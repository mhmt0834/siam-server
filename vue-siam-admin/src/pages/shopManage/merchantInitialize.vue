<template>
  <section class="merchant-initialize">
    <el-card shadow="never">
      <div slot="header">
        <span>创建商家</span>
      </div>
      <el-alert
        title="创建后店铺默认休息中，老板完善菜单、支付和桌码后再开始营业。"
        type="info"
        :closable="false">
      </el-alert>
      <el-form
        ref="form"
        :model="form"
        :rules="rules"
        label-width="130px"
        class="initialize-form">
        <el-form-item label="店铺名称" prop="shopName">
          <el-input v-model.trim="form.shopName" maxlength="100"></el-input>
        </el-form-item>
        <el-form-item label="Logo地址" prop="logo">
          <el-input v-model.trim="form.logo" placeholder="可稍后由老板在店铺基础配置上传"></el-input>
        </el-form-item>
        <el-form-item label="联系电话" prop="contactPhone">
          <el-input v-model.trim="form.contactPhone"></el-input>
        </el-form-item>
        <el-form-item label="营业时间" required>
          <el-col :span="11">
            <el-form-item prop="startTime">
              <el-time-select v-model="form.startTime" :picker-options="timeOptions"></el-time-select>
            </el-form-item>
          </el-col>
          <el-col :span="2" class="time-separator">至</el-col>
          <el-col :span="11">
            <el-form-item prop="endTime">
              <el-time-select v-model="form.endTime" :picker-options="timeOptions"></el-time-select>
            </el-form-item>
          </el-col>
        </el-form-item>
        <el-form-item label="店铺公告" prop="announcement">
          <el-input v-model.trim="form.announcement" maxlength="100"></el-input>
        </el-form-item>
        <el-divider content-position="left">老板账号</el-divider>
        <el-form-item label="登录账号" prop="ownerUsername">
          <el-input v-model.trim="form.ownerUsername" autocomplete="off"></el-input>
        </el-form-item>
        <el-form-item label="手机号" prop="ownerMobile">
          <el-input v-model.trim="form.ownerMobile" maxlength="11"></el-input>
        </el-form-item>
        <el-form-item label="初始密码" prop="initialPassword">
          <el-input v-model="form.initialPassword" type="password" autocomplete="new-password"></el-input>
        </el-form-item>
        <el-form-item label="确认密码" prop="confirmPassword">
          <el-input v-model="form.confirmPassword" type="password" autocomplete="new-password"></el-input>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="submitting" @click="submit">创建商家</el-button>
          <el-button @click="reset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </section>
</template>

<script>
export default {
  data() {
    const confirmPassword = (rule, value, callback) => {
      if (value !== this.form.initialPassword) callback(new Error('两次密码输入不一致'))
      else callback()
    }
    return {
      submitting: false,
      timeOptions: { start: '00:00', step: '00:30', end: '23:30' },
      form: this.defaultForm(),
      rules: {
        shopName: [{ required: true, message: '请输入店铺名称', trigger: 'blur' }],
        contactPhone: [{ required: true, message: '请输入联系电话', trigger: 'blur' }],
        startTime: [{ required: true, message: '请选择开始时间', trigger: 'change' }],
        endTime: [{ required: true, message: '请选择结束时间', trigger: 'change' }],
        ownerUsername: [{ required: true, message: '请输入登录账号', trigger: 'blur' }],
        ownerMobile: [
          { required: true, message: '请输入老板手机号', trigger: 'blur' },
          { pattern: /^1\d{10}$/, message: '手机号格式不正确', trigger: 'blur' }
        ],
        initialPassword: [
          { required: true, message: '请输入初始密码', trigger: 'blur' },
          { min: 8, message: '初始密码至少8位', trigger: 'blur' }
        ],
        confirmPassword: [
          { required: true, message: '请再次输入密码', trigger: 'blur' },
          { validator: confirmPassword, trigger: 'blur' }
        ]
      }
    }
  },
  methods: {
    defaultForm() {
      return {
        shopName: '',
        logo: '',
        contactPhone: '',
        startTime: '09:00',
        endTime: '22:00',
        announcement: '',
        ownerUsername: '',
        ownerMobile: '',
        initialPassword: '',
        confirmPassword: ''
      }
    },
    submit() {
      this.$refs.form.validate(valid => {
        if (!valid) return
        const param = Object.assign({}, this.form)
        delete param.confirmPassword
        this.submitting = true
        this.$http.post(this, '/rest/admin/merchant/initialize', param,
          (vue, data) => {
            vue.submitting = false
            const result = data.data || {}
            vue.$message.success(`创建成功，shopId：${result.shopId}，老板账号：${result.ownerUsername}`)
            vue.reset()
          }, (error, data) => {
            this.submitting = false
            this.form.initialPassword = ''
            this.form.confirmPassword = ''
            this.$message.error(data && data.message ? data.message : '创建失败')
          })
      })
    },
    reset() {
      this.form = this.defaultForm()
      this.$nextTick(() => this.$refs.form && this.$refs.form.clearValidate())
    }
  }
}
</script>

<style scoped>
.merchant-initialize {
  padding: 20px;
}
.initialize-form {
  width: 620px;
  margin-top: 20px;
}
.time-separator {
  text-align: center;
}
</style>
