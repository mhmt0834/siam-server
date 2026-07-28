<template>
  <div class="dashboard">
    <div class="dashboard-head">
      <div>
        <div class="eyebrow">YUKING RESTAURANT OS</div>
        <h1>经营概览</h1>
        <p>数据直接来自当前业务数据库，不展示估算值或演示指标。</p>
      </div>
      <el-button type="primary" icon="el-icon-refresh" @click="loadDashboard">刷新数据</el-button>
    </div>

    <el-row :gutter="18" class="metric-grid">
      <el-col v-for="item in metrics" :key="item.label" :span="6">
        <div class="metric-card">
          <div class="metric-top">
            <span>{{ item.label }}</span>
            <i :class="item.icon"></i>
          </div>
          <div class="metric-value">
            <small v-if="item.money">¥</small>{{ item.value }}
          </div>
          <div class="metric-note">{{ item.note }}</div>
        </div>
      </el-col>
    </el-row>

    <el-row :gutter="18" class="content-grid">
      <el-col :span="16">
        <div class="panel chart-panel">
          <div class="panel-head">
            <div>
              <h2>订单趋势</h2>
              <p>实付订单数量与金额</p>
            </div>
            <el-date-picker
              v-model="orderCountDate"
              type="daterange"
              size="small"
              unlink-panels
              range-separator="至"
              start-placeholder="开始日期"
              end-placeholder="结束日期"
              @change="filterChart">
            </el-date-picker>
          </div>
          <ve-line
            :data="chartData"
            :legend-visible="true"
            :loading="loading"
            :data-empty="dataEmpty"
            :settings="chartSettings">
          </ve-line>
        </div>
      </el-col>
      <el-col :span="8">
        <div class="panel">
          <div class="panel-head">
            <div>
              <h2>待办事项</h2>
              <p>只保留真实订单流程</p>
            </div>
          </div>
          <button class="action-row" type="button" @click="$router.push('/todayOrderList')">
            <span><i class="el-icon-s-order"></i> 待完成订单</span>
            <strong>{{ valueOf('unCompletedNum') }}</strong>
          </button>
          <button class="action-row" type="button" @click="$router.push('/refundOrderList')">
            <span><i class="el-icon-refresh-left"></i> 待处理退款</span>
            <strong>{{ valueOf('waitHandleRefundNum') }}</strong>
          </button>
          <button class="action-row" type="button" @click="$router.push('/appraiseList')">
            <span><i class="el-icon-chat-line-square"></i> 评价管理</span>
            <i class="el-icon-arrow-right"></i>
          </button>
        </div>
      </el-col>
    </el-row>

    <el-row :gutter="18" class="content-grid">
      <el-col :span="12">
        <div class="panel compact-panel">
          <div class="panel-head">
            <div>
              <h2>交易概况</h2>
              <p>累计实付、配送与退款</p>
            </div>
          </div>
          <div class="summary-list">
            <div><span>商品实付</span><strong>¥{{ moneyOf('totalActualPrice') }}</strong></div>
            <div><span>配送费</span><strong>¥{{ moneyOf('totalDeliveryFee') }}</strong></div>
            <div><span>退款金额</span><strong>¥{{ moneyOf('totalRefundAmount') }}</strong></div>
          </div>
        </div>
      </el-col>
      <el-col :span="12">
        <div class="panel compact-panel">
          <div class="panel-head">
            <div>
              <h2>顾客概况</h2>
              <p>真实注册顾客数量</p>
            </div>
          </div>
          <div class="member-grid">
            <div><strong>{{ valueOf('dayMemberCount') }}</strong><span>今日新增</span></div>
            <div><strong>{{ valueOf('yesterdayMemberCount') }}</strong><span>昨日新增</span></div>
            <div><strong>{{ valueOf('thisMonthMemberCount') }}</strong><span>本月新增</span></div>
            <div><strong>{{ valueOf('allMemberCount') }}</strong><span>顾客总数</span></div>
          </div>
        </div>
      </el-col>
    </el-row>
  </div>
</template>

<script>
  import {str2Date} from '../../utils/date'

  export default {
    name: 'statisticGraph',
    data() {
      return {
        todayList: {},
        orderRows: [],
        orderCountDate: [],
        loading: false,
        dataEmpty: false,
        chartSettings: {
          xAxisType: 'time',
          area: true,
          axisSite: { right: ['orderAmount'] },
          labelMap: { orderCount: '订单数量', orderAmount: '订单金额' }
        },
        chartData: {
          columns: ['date', 'orderCount', 'orderAmount'],
          rows: []
        }
      }
    },
    computed: {
      metrics() {
        return [
          { label: '今日实付订单', value: this.valueOf('dayCountPaid'), note: '已完成支付', icon: 'el-icon-s-order' },
          { label: '今日实付金额', value: this.moneyOf('daySumActualPrice'), note: '按实际支付统计', icon: 'el-icon-wallet', money: true },
          { label: '待完成订单', value: this.valueOf('unCompletedNum'), note: '需要继续履约', icon: 'el-icon-time' },
          { label: '待处理退款', value: this.valueOf('waitHandleRefundNum'), note: '需要人工处理', icon: 'el-icon-refresh-left' }
        ]
      }
    },
    created() {
      const end = new Date()
      const start = new Date(end.getTime() - 1000 * 60 * 60 * 24 * 14)
      this.orderCountDate = [start, end]
      this.loadDashboard()
    },
    methods: {
      valueOf(key) {
        const value = Number(this.todayList[key])
        return Number.isFinite(value) ? value : 0
      },
      moneyOf(key) {
        return this.valueOf(key).toFixed(2)
      },
      loadDashboard() {
        this.loading = true
        const vue = this
        vue.$http.post(vue, '/rest/admin/statistics/todayStatistic', {},
          (vue, data) => {
            vue.todayList = Object.assign({}, vue.todayList, data.data || {})
          },
          (error, data) => {
            vue.$message({ showClose: true, message: data.message, type: 'error' })
          }
        )
        vue.$http.post(vue, '/rest/admin/order/statistic', {},
          (vue, data) => {
            vue.orderRows = (data.data && data.data.resultList) || []
            vue.todayList = Object.assign({}, vue.todayList, data.data || {})
            vue.filterChart()
          },
          (error, data) => {
            vue.loading = false
            vue.$message({ showClose: true, message: data.message, type: 'error' })
          }
        )
      },
      filterChart() {
        const range = this.orderCountDate || []
        const start = range[0]
        const end = range[1]
        const rows = this.orderRows.filter(item => {
          if (!start || !end) return true
          const time = str2Date(item.date).getTime()
          return time >= start.getTime() && time <= end.getTime()
        })
        this.chartData = {
          columns: ['date', 'orderCount', 'orderAmount'],
          rows
        }
        this.dataEmpty = rows.length === 0
        this.loading = false
      }
    }
  }
</script>

<style scoped>
  .dashboard {
    padding: 28px;
    color: #111820;
    background: #f4f7f8;
  }
  .dashboard-head,
  .panel-head,
  .metric-top,
  .action-row,
  .summary-list > div {
    display: flex;
    align-items: center;
    justify-content: space-between;
  }
  .dashboard-head { margin-bottom: 24px; }
  .eyebrow {
    margin-bottom: 8px;
    color: #00a99a;
    font-size: 11px;
    font-weight: 800;
    letter-spacing: 2px;
  }
  h1, h2, p { margin: 0; }
  h1 { font-size: 30px; line-height: 1.2; }
  h2 { font-size: 17px; }
  p { margin-top: 7px; color: #89969b; font-size: 13px; }
  .metric-grid { margin-bottom: 18px; }
  .metric-card,
  .panel {
    background: #fff;
    border: 1px solid #edf1f2;
    border-radius: 18px;
    box-shadow: 0 10px 30px rgba(25, 48, 54, .05);
  }
  .metric-card { min-height: 126px; padding: 20px; box-sizing: border-box; }
  .metric-top { color: #66757a; font-size: 13px; }
  .metric-top i { color: #00a99a; font-size: 20px; }
  .metric-value { margin: 14px 0 8px; font-size: 28px; font-weight: 800; }
  .metric-value small { margin-right: 3px; font-size: 16px; }
  .metric-note { color: #9aa5a9; font-size: 12px; }
  .content-grid { margin-bottom: 18px; }
  .panel { padding: 22px; box-sizing: border-box; }
  .chart-panel { min-height: 430px; }
  .panel-head { margin-bottom: 20px; }
  .action-row {
    width: 100%;
    min-height: 58px;
    padding: 0;
    color: #243236;
    background: transparent;
    border: 0;
    border-bottom: 1px solid #eff2f3;
    cursor: pointer;
    text-align: left;
  }
  .action-row:hover { color: #008f82; }
  .action-row span i { margin-right: 8px; color: #00a99a; }
  .action-row strong {
    min-width: 30px;
    padding: 5px 9px;
    color: #007e73;
    background: #e7faf7;
    border-radius: 999px;
    text-align: center;
  }
  .compact-panel { min-height: 232px; }
  .summary-list > div {
    padding: 12px 0;
    border-bottom: 1px solid #f0f3f4;
    color: #69777c;
  }
  .summary-list strong { color: #111820; font-size: 18px; }
  .member-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; }
  .member-grid div {
    padding: 18px 8px;
    background: #f6faf9;
    border-radius: 14px;
    text-align: center;
  }
  .member-grid strong { display: block; color: #007e73; font-size: 22px; }
  .member-grid span { display: block; margin-top: 7px; color: #7e8b90; font-size: 12px; }
</style>
