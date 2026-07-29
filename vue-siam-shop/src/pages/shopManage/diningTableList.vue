<template>
	<section>
		<el-col :span="24" class="toolbar" style="padding-bottom: 0;">
			<el-form :inline="true" :model="searchMsg">
				<el-form-item label="餐桌编号">
					<el-input v-model="searchMsg.tableNo" clearable placeholder="例如 A08"></el-input>
				</el-form-item>
				<el-form-item label="状态">
					<el-select v-model="searchMsg.status" clearable>
						<el-option label="启用" :value="1"></el-option>
						<el-option label="停用" :value="0"></el-option>
					</el-select>
				</el-form-item>
				<el-form-item>
					<el-button type="primary" @click="getList(1)">查询</el-button>
					<el-button type="primary" @click="openEdit()">新增餐桌</el-button>
				</el-form-item>
			</el-form>
		</el-col>

		<el-table :data="list" v-loading="listLoading" style="width: 100%;">
			<el-table-column prop="tableNo" label="餐桌编号"></el-table-column>
			<el-table-column prop="tableName" label="显示名称"></el-table-column>
			<el-table-column label="状态" width="100">
				<template slot-scope="scope">
					<el-tag :type="scope.row.status === 1 ? 'success' : 'info'">
						{{ scope.row.status === 1 ? '启用' : '停用' }}
					</el-tag>
				</template>
			</el-table-column>
			<el-table-column prop="updateTime" label="更新时间" :formatter="formatTime"></el-table-column>
			<el-table-column label="操作" fixed="right" width="260">
				<template slot-scope="scope">
					<el-button size="small" @click="openEdit(scope.row)">编辑</el-button>
					<el-button size="small" type="primary" @click="showQr(scope.row)">桌码</el-button>
					<el-button size="small" type="warning" @click="regenerateScene(scope.row)">换码</el-button>
				</template>
			</el-table-column>
		</el-table>

		<el-col :span="24" class="toolbar">
			<el-pagination
				@size-change="handleSizeChange"
				@current-change="handleCurrentChange"
				:page-sizes="[10, 20, 50]"
				:page-size="searchMsg.pageSize"
				layout="total, sizes, prev, pager, next, jumper"
				:total="total"
				style="float: right;">
			</el-pagination>
		</el-col>

		<el-dialog :title="editForm.id ? '编辑餐桌' : '新增餐桌'" :visible.sync="editVisible" :close-on-click-modal="false">
			<el-form ref="editForm" :model="editForm" :rules="rules" label-width="110px">
				<el-form-item label="餐桌编号" prop="tableNo">
					<el-input v-model="editForm.tableNo" placeholder="例如 A08"></el-input>
				</el-form-item>
				<el-form-item label="显示名称" prop="tableName">
					<el-input v-model="editForm.tableName" placeholder="例如 A08桌"></el-input>
				</el-form-item>
				<el-form-item label="状态" prop="status">
					<el-radio-group v-model="editForm.status">
						<el-radio :label="1">启用</el-radio>
						<el-radio :label="0">停用</el-radio>
					</el-radio-group>
				</el-form-item>
			</el-form>
			<div slot="footer">
				<el-button @click="editVisible = false">取消</el-button>
				<el-button type="primary" :loading="editLoading" @click="submitEdit">保存</el-button>
			</div>
		</el-dialog>

		<el-dialog title="餐桌小程序码参数" :visible.sync="qrVisible">
			<el-alert
				title="正式小程序码图片需在商家 AppID 配置完成后由服务端生成；当前路径可用于微信开发者工具测试。"
				type="info"
				:closable="false">
			</el-alert>
			<el-form label-width="100px" style="margin-top: 20px;">
				<el-form-item label="餐桌">
					<span>{{ qrInfo.tableName }}（{{ qrInfo.tableNo }}）</span>
				</el-form-item>
				<el-form-item label="小程序路径">
					<el-input v-model="qrInfo.pagePath" readonly>
						<el-button slot="append" @click="copyPath">复制</el-button>
					</el-input>
				</el-form-item>
				<el-form-item label="场景值">
					<el-input v-model="qrInfo.sceneToken" readonly></el-input>
				</el-form-item>
			</el-form>
		</el-dialog>
	</section>
</template>

<script>
export default {
	data() {
		return {
			searchMsg: { pageNo: 1, pageSize: 20, tableNo: '', status: '' },
			list: [],
			total: 0,
			listLoading: false,
			editVisible: false,
			editLoading: false,
			editForm: { tableNo: '', tableName: '', status: 1 },
			rules: {
				tableNo: [{ required: true, message: '请输入餐桌编号', trigger: 'blur' }]
			},
			qrVisible: false,
			qrInfo: {}
		}
	},
	methods: {
		getList(pageNo) {
			if (pageNo) this.searchMsg.pageNo = pageNo
			this.listLoading = true
			this.$http.post(this, '/rest/merchant/diningTable/list', Object.assign({}, this.searchMsg),
				(vue, data) => {
					vue.list = data.data.records
					vue.total = data.data.total
					vue.listLoading = false
				},
				(error, data) => {
					this.listLoading = false
					this.$message.error(data.message)
				})
		},
		handleSizeChange(size) {
			this.searchMsg.pageSize = size
			this.getList(1)
		},
		handleCurrentChange(page) {
			this.searchMsg.pageNo = page
			this.getList()
		},
		formatTime(row, column) {
			if (!row[column.property]) return '-'
			return this.$utils.formatDate(new Date(row[column.property]), 'yyyy-MM-dd hh:mm:ss')
		},
		openEdit(row) {
			this.editForm = row
				? { id: row.id, tableNo: row.tableNo, tableName: row.tableName, status: row.status }
				: { tableNo: '', tableName: '', status: 1 }
			this.editVisible = true
		},
		submitEdit() {
			this.$refs.editForm.validate(valid => {
				if (!valid) return
				this.editLoading = true
				const url = this.editForm.id
					? '/rest/merchant/diningTable/update'
					: '/rest/merchant/diningTable/insert'
				this.$http.post(this, url, Object.assign({}, this.editForm),
					(vue, data) => {
						vue.editLoading = false
						vue.editVisible = false
						vue.$message.success(data.message || '保存成功')
						vue.getList()
					},
					(error, data) => {
						this.editLoading = false
						this.$message.error(data.message)
					})
			})
		},
		showQr(row) {
			this.$http.post(this, '/rest/merchant/diningTable/generateQr', { id: row.id },
				(vue, data) => {
					vue.qrInfo = data.data
					vue.qrVisible = true
				},
				(error, data) => this.$message.error(data.message))
		},
		regenerateScene(row) {
			this.$confirm('换码后旧桌码立即失效，确认继续吗？', '提示', { type: 'warning' })
				.then(() => {
					this.$http.post(this, '/rest/merchant/diningTable/regenerateScene', { id: row.id },
						(vue, data) => {
							vue.qrInfo = data.data
							vue.qrVisible = true
							vue.getList()
						},
						(error, data) => this.$message.error(data.message))
				})
				.catch(() => {})
		},
		copyPath() {
			const input = document.createElement('textarea')
			input.value = this.qrInfo.pagePath || ''
			document.body.appendChild(input)
			input.select()
			document.execCommand('copy')
			document.body.removeChild(input)
			this.$message.success('已复制小程序路径')
		}
	},
	mounted() {
		this.getList()
		this.$orderPrint.init()
	}
}
</script>
