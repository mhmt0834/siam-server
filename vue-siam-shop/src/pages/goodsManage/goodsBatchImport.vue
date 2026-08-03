<template>
  <section class="goods-batch-import">
    <el-card shadow="never">
      <div slot="header" class="page-header">
        <span>批量添加菜品</span>
        <div>
          <el-upload
            action=""
            accept=".xlsx"
            :show-file-list="false"
            :http-request="importExcel">
            <el-button :loading="uploading">导入Excel</el-button>
          </el-upload>
          <el-button type="primary" :loading="submitting" @click="submit">保存全部</el-button>
        </div>
      </div>
      <el-alert
        title="最多500条；图片填写已上传后的资源地址。Excel仅支持xlsx格式，列模板见商家接入手册。"
        type="info"
        :closable="false">
      </el-alert>
      <el-table :data="items" class="batch-table">
        <el-table-column type="index" label="#" width="50"></el-table-column>
        <el-table-column label="菜品名称" min-width="140">
          <template slot-scope="scope">
            <el-input v-model.trim="scope.row.name" maxlength="100"></el-input>
          </template>
        </el-table-column>
        <el-table-column label="分类" min-width="130">
          <template slot-scope="scope">
            <el-select
              v-model.trim="scope.row.categoryName"
              filterable
              allow-create
              default-first-option
              placeholder="选择或新建分类">
              <el-option v-for="menu in menus" :key="menu.id" :label="menu.name" :value="menu.name"></el-option>
            </el-select>
          </template>
        </el-table-column>
        <el-table-column label="图片地址" min-width="200">
          <template slot-scope="scope">
            <el-input v-model.trim="scope.row.image" placeholder="data/images/merchant/..."></el-input>
          </template>
        </el-table-column>
        <el-table-column label="价格" width="120">
          <template slot-scope="scope">
            <el-input-number v-model="scope.row.price" :min="0.01" :precision="2" :controls="false"></el-input-number>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="120">
          <template slot-scope="scope">
            <el-select v-model="scope.row.status">
              <el-option label="待上架" :value="1"></el-option>
              <el-option label="已上架" :value="2"></el-option>
              <el-option label="已下架" :value="3"></el-option>
              <el-option label="售罄" :value="4"></el-option>
            </el-select>
          </template>
        </el-table-column>
        <el-table-column label="介绍" min-width="160">
          <template slot-scope="scope">
            <el-input v-model.trim="scope.row.description"></el-input>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="80">
          <template slot-scope="scope">
            <el-button type="text" :disabled="items.length === 1" @click="remove(scope.$index)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-button icon="el-icon-plus" @click="add">继续添加</el-button>
    </el-card>
  </section>
</template>

<script>
export default {
  data() {
    return {
      items: [this.emptyItem()],
      menus: [],
      submitting: false,
      uploading: false
    }
  },
  created() {
    this.loadMenus()
  },
  methods: {
    emptyItem() {
      return { name: '', categoryName: '', image: '', price: 0.01, status: 1, description: '' }
    },
    add() {
      if (this.items.length >= 500) return this.$message.warning('单次最多500条')
      this.items.push(this.emptyItem())
    },
    remove(index) {
      this.items.splice(index, 1)
    },
    loadMenus() {
      this.$http.post(this, '/rest/merchant/menu/list', { pageNo: -1, pageSize: 500 },
        (vue, data) => { vue.menus = (data.data && data.data.records) || [] },
        (error, data) => this.$message.error(data && data.message ? data.message : '分类加载失败'))
    },
    submit() {
      this.submitting = true
      this.$http.post(this, '/rest/merchant/goods/batchInsert', { items: this.items },
        (vue, data) => {
          vue.submitting = false
          vue.$message.success(`成功导入${data.data.importedCount}个菜品`)
          vue.$router.push({ path: '/goodsList' })
        }, (error, data) => {
          this.submitting = false
          this.$message.error(data && data.message ? data.message : '批量导入失败')
        })
    },
    importExcel(option) {
      const formData = new FormData()
      formData.append('file', option.file)
      this.uploading = true
      this.$http.postupload(this, '/rest/merchant/goods/import', formData,
        (vue, data) => {
          vue.uploading = false
          option.onSuccess()
          vue.$message.success(`成功导入${data.data.importedCount}个菜品`)
          vue.$router.push({ path: '/goodsList' })
        }, (error, data) => {
          this.uploading = false
          option.onError()
          this.$message.error(data && data.message ? data.message : 'Excel导入失败')
        })
    }
  }
}
</script>

<style scoped>
.goods-batch-import {
  padding: 20px;
}
.page-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.page-header > div {
  display: flex;
  gap: 10px;
}
.batch-table {
  margin: 20px 0;
}
</style>
