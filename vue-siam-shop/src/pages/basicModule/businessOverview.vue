<template>
  <div class="app-container business-overview">
    <div class="overview-header">
      <div>
        <h2>经营概览</h2>
        <p>数据仅统计已完成订单</p>
      </div>
      <el-tag :type="todayData.isOperating ? 'success' : 'info'" effect="plain">
        {{ todayData.isOperating ? '营业中' : '休息中' }}
      </el-tag>
    </div>

    <el-row :gutter="20" class="metric-row">
      <el-col :span="8">
        <el-card shadow="never" class="metric-card">
          <div class="metric-label">今日营业额</div>
          <div class="metric-value">¥{{ formatMoney(todayData.todayRevenue) }}</div>
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card shadow="never" class="metric-card">
          <div class="metric-label">今日订单数</div>
          <div class="metric-value">{{ todayData.todayOrderCount || 0 }}</div>
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card shadow="never" class="metric-card">
          <div class="metric-label">今日客单价</div>
          <div class="metric-value">¥{{ formatMoney(todayData.averageOrderAmount) }}</div>
        </el-card>
      </el-col>
    </el-row>

    <el-card shadow="never" class="section-card">
      <div slot="header" class="section-header">
        <span>营业趋势</span>
        <el-radio-group v-model="range" size="small" @change="loadRangeData">
          <el-radio-button label="today">今日</el-radio-button>
          <el-radio-button label="7d">最近7天</el-radio-button>
          <el-radio-button label="30d">最近30天</el-radio-button>
        </el-radio-group>
      </div>
      <ve-line
        :data="trendChartData"
        :settings="chartSettings"
        :loading="trendLoading"
        :legend-visible="true">
      </ve-line>
    </el-card>

    <el-row :gutter="20">
      <el-col :span="12">
        <el-card shadow="never" class="section-card">
          <div slot="header" class="section-header">
            <span>热销菜品 TOP 10</span>
            <span class="range-tip">{{ rangeLabel }}</span>
          </div>
          <el-table :data="hotGoods" v-loading="hotGoodsLoading" height="420">
            <el-table-column prop="rank" label="排名" width="60"></el-table-column>
            <el-table-column prop="goodsName" label="菜品"></el-table-column>
            <el-table-column prop="salesQuantity" label="销量" width="80"></el-table-column>
            <el-table-column label="销售额" width="110">
              <template slot-scope="scope">¥{{ formatMoney(scope.row.salesAmount) }}</template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>

      <el-col :span="12">
        <el-card shadow="never" class="section-card">
          <div slot="header" class="section-header">
            <span>商品经营分析</span>
            <span class="range-tip">平均销量 {{ goodsAnalysis.averageSalesQuantity || 0 }}</span>
          </div>
          <div class="analysis-summary">
            <el-tag type="success">热销 {{ goodsAnalysis.hotGoodsCount || 0 }}</el-tag>
            <el-tag>普通 {{ goodsAnalysis.regularGoodsCount || 0 }}</el-tag>
            <el-tag type="info">低销量 {{ goodsAnalysis.lowSalesGoodsCount || 0 }}</el-tag>
          </div>
          <el-table :data="goodsAnalysis.goods" v-loading="analysisLoading" height="370">
            <el-table-column prop="goodsName" label="菜品"></el-table-column>
            <el-table-column prop="salesQuantity" label="销量" width="70"></el-table-column>
            <el-table-column label="分类" width="110">
              <template slot-scope="scope">
                <el-tag :type="categoryTagType(scope.row.category)" size="small">
                  {{ scope.row.categoryName }}
                </el-tag>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script>
export default {
  name: 'businessOverview',
  data() {
    return {
      range: '7d',
      todayData: {
        todayRevenue: 0,
        todayOrderCount: 0,
        averageOrderAmount: 0,
        isOperating: false
      },
      trendChartData: {
        columns: ['date', 'revenue', 'orderCount'],
        rows: []
      },
      chartSettings: {
        axisSite: { right: ['orderCount'] },
        yAxisType: ['normal', 'normal'],
        labelMap: {
          date: '日期',
          revenue: '营业额',
          orderCount: '订单数'
        }
      },
      hotGoods: [],
      goodsAnalysis: { goods: [] },
      trendLoading: false,
      hotGoodsLoading: false,
      analysisLoading: false
    }
  },
  computed: {
    rangeLabel() {
      return this.range === 'today' ? '今日' : (this.range === '7d' ? '最近7天' : '最近30天')
    }
  },
  created() {
    this.loadToday()
    this.loadRangeData()
  },
  methods: {
    loadToday() {
      this.$http.post(this, '/rest/merchant/statistics/today', {},
        (vue, data) => {
          vue.todayData = data.data || vue.todayData
        }, this.showError)
    },
    loadRangeData() {
      this.loadTrend()
      this.loadHotGoods()
      this.loadGoodsAnalysis()
    },
    loadTrend() {
      this.trendLoading = true
      this.$http.post(this, '/rest/merchant/statistics/trend', { range: this.range },
        (vue, data) => {
          vue.trendChartData.rows = data.data || []
          vue.trendLoading = false
        }, (error, data) => {
          this.trendLoading = false
          this.showError(error, data)
        })
    },
    loadHotGoods() {
      this.hotGoodsLoading = true
      this.$http.post(this, '/rest/merchant/statistics/hotGoods', { range: this.range },
        (vue, data) => {
          vue.hotGoods = data.data || []
          vue.hotGoodsLoading = false
        }, (error, data) => {
          this.hotGoodsLoading = false
          this.showError(error, data)
        })
    },
    loadGoodsAnalysis() {
      this.analysisLoading = true
      this.$http.post(this, '/rest/merchant/statistics/goodsAnalysis', { range: this.range },
        (vue, data) => {
          vue.goodsAnalysis = data.data || { goods: [] }
          vue.analysisLoading = false
        }, (error, data) => {
          this.analysisLoading = false
          this.showError(error, data)
        })
    },
    showError(error, data) {
      this.$message({
        showClose: true,
        message: data && data.message ? data.message : '经营数据加载失败',
        type: 'error'
      })
    },
    formatMoney(value) {
      return Number(value || 0).toFixed(2)
    },
    categoryTagType(category) {
      if (category === 'HOT') return 'success'
      if (category === 'LOW') return 'info'
      return ''
    }
  }
}
</script>

<style scoped>
.business-overview {
  background: #f7f7f7;
  min-height: calc(100vh - 84px);
}
.overview-header,
.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.overview-header {
  margin-bottom: 20px;
}
.overview-header h2 {
  margin: 0 0 6px;
  color: #1c1c1e;
  font-size: 22px;
}
.overview-header p,
.range-tip {
  margin: 0;
  color: #909399;
  font-size: 13px;
}
.metric-row {
  margin-bottom: 20px;
}
.metric-card,
.section-card {
  border-color: #eaeaea;
}
.metric-label {
  color: #666;
  font-size: 14px;
}
.metric-value {
  margin-top: 14px;
  color: #000;
  font-size: 30px;
  font-weight: 600;
}
.section-card {
  margin-bottom: 20px;
}
.section-header > span:first-child {
  color: #1c1c1e;
  font-size: 16px;
  font-weight: 600;
}
.analysis-summary {
  display: flex;
  gap: 10px;
  margin-bottom: 14px;
}
</style>
