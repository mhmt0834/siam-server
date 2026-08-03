// 已完成订单
<template>
	<section>
		<!--工具条-->
		<el-col :span="24" class="toolbar" style="padding-bottom: 0px;">
			<el-form :inline="true" :model="searchMsg">
				<el-form-item>
					<el-select v-model="searchMsg.shoppingWay" placeholder="请选择购物方式搜索" clearable>
						<el-option label="自取" :value="1"></el-option>
						<el-option label="配送" :value="2"></el-option>    
					</el-select>
				</el-form-item>           
				<el-form-item>
					<el-input v-model="searchMsg.queueNo" placeholder="请输入取餐号搜索" clearable></el-input>
				</el-form-item>     
				<el-form-item>
					<el-input v-model="searchMsg.contactPhone" placeholder="请输入联系电话搜索" clearable></el-input>
				</el-form-item>            
				<!-- <el-form-item>
					<el-input v-model="searchMsg.contactRealname" placeholder="请输入联系人姓名搜索" clearable></el-input>
				</el-form-item>                 
				<el-form-item>
					<el-input v-model="searchMsg.fullReductionRuleDescription" placeholder="请输入满减规则名称搜索" clearable></el-input>
				</el-form-item>     
				<el-form-item>
					<el-input v-model="searchMsg.couponsDescription" placeholder="请输入优惠卷名称搜索" clearable></el-input>
				</el-form-item>     
				<el-form-item>
					<el-input v-model="searchMsg.contactStreet" placeholder="请输入收货地址搜索" clearable></el-input>
				</el-form-item> -->
				<el-form-item label="">
					<el-date-picker
					v-model="searchMsg.createTime"
					type="daterange"
					align="right"
					unlink-panels
					range-separator="至"
					start-placeholder="开始日期"
					end-placeholder="结束日期"
					:picker-options="pickerOptions">
					</el-date-picker>
				</el-form-item>       
				<el-form-item>
					<el-button type="primary" @click="getList(1)">查询</el-button>
				</el-form-item>
			</el-form>
		</el-col>
		<!--列表-->
		<el-table :data="list" highlight-current-row v-loading="listLoading" style="width: 100%;" :cell-style="cellStyle" :header-cell-style="headerCellStyle" :row-class-name="tableRowClassName">
			<!-- <el-table-column type="index" label="序号" width="50">
				<template scope="scope">
					<span>{{(searchMsg.pageNo - 1) * searchMsg.pageSize + scope.$index + 1}}</span>
				</template>		
			</el-table-column>       -->
      <el-table-column prop="orderNo" label="订单号" width="180"></el-table-column>
      <el-table-column label="桌号" width="100">
				<template slot-scope="scope">{{scope.row.tableName || scope.row.tableNo || '-'}}</template>
			</el-table-column>
      <el-table-column prop="goodsSummary" label="商品明细" min-width="180">
				<template slot-scope="scope">{{scope.row.goodsSummary || formatDescription(scope.row)}}</template>
			</el-table-column>
      <el-table-column prop="goodsTotalPrice" label="订单总额">
				<template scope="scope">
					<span>{{scope.row.goodsTotalPrice + scope.row.packingCharges + scope.row.deliveryFee}}元</span>
				</template>      
      </el-table-column>   
       <el-table-column prop="paymentMode" label="支付方式">
				<template scope="scope">
					<span v-if="scope.row.paymentMode == 1">微信支付</span>
                    <span v-else-if="scope.row.paymentMode == 0">平台余额</span>
               </template>						
			</el-table-column>	   
      <el-table-column prop="actualPrice" label="实付款" :formatter="addUnit"></el-table-column>
      <el-table-column prop="goodsTotalQuantity" label="商品总数量">
				<template scope="scope">
					<span>{{scope.row.goodsTotalQuantity}}件</span>
				</template>    
      </el-table-column>
      <el-table-column prop="remark" label="备注"></el-table-column>      
			<el-table-column prop="shoppingWay" label="购物方式" :formatter="formatShoppingWay"></el-table-column>      
      <el-table-column prop="contactRealname" label="联系人姓名" width="120"></el-table-column>
			<el-table-column prop="contactPhone" label="联系电话" width="120"></el-table-column>
      <el-table-column prop="contactProvince" label="派送地址" width="190">
				<template slot-scope="scope">
					{{scope.row.contactProvince}} - {{scope.row.contactCity}} - {{scope.row.contactArea}} - {{scope.row.contactStreet}} - {{scope.row.contactHouseNumber}}
				</template>
      </el-table-column>			      
      <el-table-column prop="status" label="订单状态" width="100" :formatter="formatOrder"></el-table-column>
			<el-table-column prop="createTime" label="下单时间" :formatter="formatTime" width="190"></el-table-column>
			<el-table-column label="操作" fixed="right">
				<template slot-scope="scope">
          <el-button size="small" @click="gotoOtherPage('view', scope.row)">查看详情</el-button>
					<el-button type="primary" size="small" v-if="scope.row.status == 2" :loading="operatingOrderId === scope.row.id" @click="acceptOrder(scope.row)">接单</el-button>
					<el-button type="success" size="small" v-if="scope.row.status == 3" :loading="operatingOrderId === scope.row.id" @click="completeOrder(scope.row)">完成订单</el-button>
					<!-- <el-button size="small" v-if="scope.row.status == 0" @click="handleEdit(scope.row)">配送</el-button> -->
					<!-- <el-button size="small" v-if="scope.row.status == 4" @click="openDialog(scope.row.id)">申诉处理</el-button> -->
					<!-- <el-button size="small" v-if="scope.row.status == 4" @click="openDialog(scope.row.id, 1)">退款</el-button> -->
					<!-- <el-button type="danger" size="small" @click="handleDel(scope.row.id)">删除</el-button> -->
				</template>
			</el-table-column>
		</el-table>

		<!--工具条-->
		<el-col :span="24" class="toolbar">
			<el-pagination
				@size-change="handleSizeChange"
				@current-change="handleCurrentChange"
				:page-sizes="[10, 20, 50, 100]"
				:page-size="searchMsg.pageSize"
				layout="total, sizes, prev, pager, next, jumper"
				:total="total"
				style="float:right;">
			</el-pagination>
		</el-col>

		<!--编辑界面-->
		<el-dialog :title="dialogTitle" :visible.sync="editFormVisible" @close="editFormClose" :close-on-click-modal="false">
			<el-form size="small" :model="editForm" class="editForm" label-width="80px" style="width: 80%;">
        <el-form-item prop="dealadvise" label="处理意见">
          <el-input type="textarea"  placeholder="处理意见" v-model="editForm.dealadvise"></el-input>
        </el-form-item>
        <el-form-item>
          <el-button @click="dealOption">保存</el-button>
        </el-form-item>
			</el-form>
			<!-- <div slot="footer" class="dialog-footer">
				<el-button @click.native="editFormVisible = false">关闭</el-button>
			</div> -->
		</el-dialog>
	</section>
</template>
<script>
	export default {
		data() {
			return {
				pickerOptions: {
					shortcuts: [{
						text: '最近一周',
							onClick(picker) {
							const end = new Date();
							let start = new Date();
							start.setTime(end.getTime() - 1000 * 60 * 60 * 24 * 7);
							picker.$emit('pick', [start, end]);
						}
					}, {
						text: '最近两周',
							onClick(picker) {
							const end = new Date();
							let start = new Date();
							start.setTime(end.getTime() - 1000 * 60 * 60 * 24 * 14);
							picker.$emit('pick', [start, end]);
						}
					}, {
						text: '最近一月',
						onClick(picker) {
							const end = new Date();
							let start = new Date();
							start.setTime(end.getTime() - 1000 * 60 * 60 * 24 * 30);
							picker.$emit('pick', [start, end]);
						}
					}, {
						text: '最近三月',
						onClick(picker) {
							const end = new Date();
							let start = new Date();
							start.setTime(end.getTime() - 1000 * 60 * 60 * 24 * 30 * 3);
							picker.$emit('pick', [start, end]);
						}
					}, {
						text: '最近半年',
						onClick(picker) {
							const end = new Date();
							let start = new Date();
							start.setTime(end.getTime() - 1000 * 60 * 60 * 24 * 180);
							picker.$emit('pick', [start, end]);
						}
					}, {
						text: '最近一年',
						onClick(picker) {
							const end = new Date();
							let start = new Date();
							start.setTime(end.getTime() - 1000 * 60 * 60 * 24 * 30 * 12);
							picker.$emit('pick', [start, end]);
						}
					}, {
						text: '最近两年',
						onClick(picker) {
							const end = new Date();
							let start = new Date();
							start.setTime(end.getTime() - 1000 * 60 * 60 * 24 * 30 * 24);
							picker.$emit('pick', [start, end]);
						}
					}, {
						text: '最近三年',
						onClick(picker) {
							const end = new Date();
							let start = new Date();
							start.setTime(end.getTime() - 1000 * 60 * 60 * 24 * 30 * 36);
							picker.$emit('pick', [start, end]);
						}
					}]
				},        
				searchMsg: {
					pageNo: 1,
					pageSize: 20
				},
				list: [],
				total: 0,
				listLoading: false,
				sels: [],//列表选中列
				editFormVisible: false,//编辑界面是否显示
				//编辑界面数据
				editForm: {},
        searchData:[],
        dealtype: '',
        dealId: '',
        dialogTitle: '申诉处理',
				// 实时通知与断线轮询
				timer: null,
				websocket: null,
				websocketConnected: false,
				reconnectTimer: null,
				heartbeatTimer: null,
				highlightOrderId: null,
				operatingOrderId: null
			}
		},
		methods: {
      tableRowClassName({row}) {
        return row.id === this.highlightOrderId ? 'new-order-row' : '';
      },
      cellStyle({row, column, rowIndex, columnIndex}){
        return "text-align:center";
      },
      headerCellStyle({row, rowIndex}){
        return "text-align:center";
      },      
			gotoOtherPage(type, row) {
				if(type === 'view') {
					this.$router.push({path:'orderDetail', query:{id: row.id}})
				}
			},
      dealOption() {
        let vue = this
        let url = ''
        let param = {
          id: vue.dealId,
          dealadvise: vue.editForm.dealadvise
        }
        vue.dealtype ? url = '/rest/merchant/order/updateOrderByBack' : url = '/rest/merchant/order/updateByDealadvise'
        vue.$http.post( vue, url, param,
          (vue, data) => {
            vue.$message({
              showClose: true,
              message: data.message,
              type: 'success'
            });
            vue.editFormVisible = false
            vue.getList()
          }, (error, data) => {
            vue.$message({
              showClose: true,
              message: data.message,
              type: 'error'
            });
          }
        )
      },
      openDialog(id, type = 0) {
        this.editFormVisible = true
        this.dealId = id
        this.dealtype = type
        type ? this.dialogTitle = '退款' : '申诉处理'
      },
      editFormClose() {
        this.editForm = {}
      },
      addStand() { // 新增规格
        let vue = this
        let param = Object.assign({}, vue.editForm)
        let regEn = /^[1-9]\d*$/;
        if (!regEn.test(param.sort)) {
          vue.$message({
            showClose: true,
            message: '输入正整数序号',
            type: 'error'
          });
          return false
        }
        if (!param.stand) {
          vue.$message({
            showClose: true,
            message: '请输入规格',
            type: 'error'
          });
          return false
        }
        vue.$http.post( vue, '/rest/merchant/stand/update', param,
          (vue, data) => {
            vue.$message({
              showClose: true,
              message: data.message,
              type: 'success'
            });
            vue.editFormVisible = false
            vue.getList()
          }, (error, data) => {
            vue.$message({
              showClose: true,
              message: data.message,
              type: 'error'
            });
          }
        )
      },
      addUnit(row, column) { // 添加单位
        return (row[column.property] || 0) + '元'
      },
      formatShoppingWay(row, column) { // 添加单位
        let shoppingWayText = row.shoppingWay == 1 ? '自取' : '配送';
        if(row.isChangeToDelivery){
          shoppingWayText = '由自取订单改为配送';
        }      
        return shoppingWayText;
      },           
      formatDescription(row, column) { // 添加单位
        //let replaceReg = new RegExp("&nbsp;", 'g');
        //return row.description.replace(/1/g, " ");
        if(row.description!=undefined){
          return row.description.replace(/&nbsp;/g, " ")
        }else{
          return "-";
        }
      },      
			formatTime(row, column) {
				let date = new Date(row[column.property]);
				return this.$utils.formatDate(date, 'yyyy-MM-dd hh:mm');
			},
      formatOrder (row, column) { // 0-待配送 1-待收货 2已完成 3-已取消 4-申诉中 5-已退款 6-申诉已完成
        let status = row[column.property] 
        switch (status) {
          case 1:
            return '未付款'
            break;
          case 2:
            return '待接单'
            break;
          case 3:
            return '制作中'
            break;
          case 4:
              return '待配送'
            break;
          case 5:
            return '已配送'
            break;
          case 6:
            return '已完成'
            break;
          case 7:
            return '售后处理中'
            break;
          case 8:
            return '已退款'
            break;
          case 9:
            return '售后处理完成'
            break;         
          case 10:
            return '已取消(未支付)'
            break;                  
          case 11:
            return '已取消(已支付)'
            break;                     
        }
      },
			handleSizeChange(val) {
				this.searchMsg.pageSize = val;
				this.getList();
			},      
			handleCurrentChange(val) {
				this.searchMsg.pageNo = val;
				this.getList();
			},
      getList(pageNoParam) { // 获取列表
				if(pageNoParam){
				  this.searchMsg.pageNo = pageNoParam;
        }
        // 获取订单列表
				let vue = this
        let param = Object.assign({}, vue.searchMsg)

				//处理开始日期、结束日期
				if(vue.searchMsg.createTime){
					let startDate = vue.searchMsg.createTime[0];
					let endDate = vue.searchMsg.createTime[1];
					param.startCreateTime = this.$utils.formatDate(new Date(startDate), 'yyyy/MM/dd hh:mm:ss');
					param.endCreateTime = this.$utils.formatDate(new Date(endDate), 'yyyy/MM/dd hh:mm:ss');
					delete param.createTime;
				}

        vue.listLoading = true;
				vue.$http.post(vue, '/rest/merchant/order/todayOrderList', param,
					(vue, data) => {
						vue.list = data.data.records
						vue.total = data.data.total
						vue.listLoading = false;
					},(error, data)=> {
						vue.listLoading = false;
						vue.$message({
							showClose: true,
							message: data.message,
							type: 'error'
						});
					}
				)
			},
			acceptOrder(row) {
				this.transitionOrder(row, '/rest/merchant/order/accept', '接单成功');
			},
			completeOrder(row) {
				this.transitionOrder(row, '/rest/merchant/order/complete', '订单已完成');
			},
			transitionOrder(row, url, successMessage) {
				if (this.operatingOrderId) return;
				let vue = this;
				vue.operatingOrderId = row.id;
				vue.$http.post(vue, url, {id: row.id},
					(vue) => {
						vue.operatingOrderId = null;
						vue.$message({showClose: true, message: successMessage, type: 'success'});
						vue.getList();
					},
					(error, data) => {
						vue.operatingOrderId = null;
						vue.$message({showClose: true, message: data && data.message ? data.message : '操作失败', type: 'error'});
					}
				);
			},
			connectRealtime() {
				const token = sessionStorage.getItem('token');
				if (!token || typeof WebSocket === 'undefined') return;
				const baseUrl = this.$http.getUrl().replace(/\/$/, '');
				const websocketUrl = baseUrl.replace(/^http:/, 'ws:').replace(/^https:/, 'wss:') +
					'/rest/merchant/order/realtime?token=' + encodeURIComponent(token);
				this.closeRealtime();
				const vue = this;
				vue.websocket = new WebSocket(websocketUrl);
				vue.websocket.onopen = function() {
					vue.websocketConnected = true;
					vue.heartbeatTimer = setInterval(() => {
						if (vue.websocket && vue.websocket.readyState === WebSocket.OPEN) vue.websocket.send('PING');
					}, 25000);
				};
				vue.websocket.onmessage = function(event) {
					if (event.data === 'PONG') return;
					try {
						const message = JSON.parse(event.data);
						vue.handleRealtimeMessage(message);
					} catch (ignored) {}
				};
				vue.websocket.onerror = function() { vue.websocketConnected = false; };
				vue.websocket.onclose = function() {
					vue.websocketConnected = false;
					clearInterval(vue.heartbeatTimer);
					vue.reconnectTimer = setTimeout(() => vue.connectRealtime(), 5000);
				};
			},
			handleRealtimeMessage(message) {
				if (!message || !message.type) return;
				if (message.type === 'NEW_ORDER') {
					this.highlightOrderId = message.orderId;
					this.$notify({title: '新订单', message: '收到新的店内订单，请及时接单', type: 'success', duration: 0});
					this.playNewOrderSound();
					setTimeout(() => { this.highlightOrderId = null; }, 30000);
				}
				this.getList(1);
			},
			playNewOrderSound() {
				try {
					const AudioContext = window.AudioContext || window.webkitAudioContext;
					if (!AudioContext) return;
					const context = new AudioContext();
					const oscillator = context.createOscillator();
					const gain = context.createGain();
					oscillator.frequency.value = 880;
					gain.gain.setValueAtTime(0.2, context.currentTime);
					gain.gain.exponentialRampToValueAtTime(0.01, context.currentTime + 0.8);
					oscillator.connect(gain);
					gain.connect(context.destination);
					oscillator.start();
					oscillator.stop(context.currentTime + 0.8);
				} catch (ignored) {}
			},
			closeRealtime() {
				clearTimeout(this.reconnectTimer);
				clearInterval(this.heartbeatTimer);
				if (this.websocket) {
					this.websocket.onclose = null;
					this.websocket.close();
					this.websocket = null;
				}
				this.websocketConnected = false;
			},
			handleDel (id) { // 删除
				this.$confirm('确认删除该记录吗?', '提示', {
					type: 'warning'
				}).then(() => {
					// this.listLoading = true;
				let vue = this;
				vue.$http.post(vue, '/rest/merchant/stand/deleteById', {id},
					function(vue, data) {
            vue.$message({
              showClose: true,
              message: data.message,
              type: 'success'
            });
            vue.getList()
					}, function(error, data) {
            vue.$message({
              showClose: true,
              message: data.message,
              type: 'error'
            });
					}
				)
					// this.listLoading = false;
				}).catch(() => {});
			},
			handleEdit (row) { // 显示编辑界面
        let vue = this;
        let param = {
          orderid: row.id,
          status: 1
        }
				vue.$http.post(vue, '/rest/merchant/order/updateOrderState', param,
					function(vue, data) {
            vue.$message({
              showClose: true,
              message: data.message,
              type: 'success'
            });
            vue.getList()
					}, function(error, data) {
            vue.$message({
              showClose: true,
              message: data.message,
              type: 'error'
            });
					}
				)
      }
		},
		mounted() {
      this.getList();
			this.connectRealtime();
			// WebSocket 断开时每 10 秒轮询，避免漏单
			this.timer = setInterval(() => {
				if (!this.websocketConnected) this.getList();
			}, 10*1000);
    },
    beforeDestroy(){
      //清除定时任务，否则切换到其他页面，这定时任务依旧会执行
      clearInterval(this.timer);
			this.closeRealtime();
    }
	}

</script>

<style scoped>
.el-button+.el-button {
  margin-top: 5px;
  margin-left: 0;
}
.editForm .el-input {
  width: 300px;
}
/deep/ .new-order-row td {
	background: #f2f2f2 !important;
}
</style>
