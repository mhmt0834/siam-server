<template>
    <section>
        <el-form :model="ruleForm" :rules="rules" ref="ruleForm" label-position="left" label-width="0px" class="login-container">
            <div class="console-tag">OPERATIONS CONSOLE</div>
            <div class="title"><span>{{ brand.consoleName }}</span></div>
            <div class="subtitle">高效管理门店、商品与订单</div>
            <el-form-item prop="name">
                <el-input prefix-icon="el-icon-myuser" type="text" v-model="ruleForm.name" @keyup.enter.native="handleSubmit" auto-complete="off" placeholder="账号"></el-input>
            </el-form-item>
            <el-form-item prop="password">
                <el-input prefix-icon="el-icon-mylock" type="password" @keyup.enter.native="handleSubmit" v-model="ruleForm.password" auto-complete="off" placeholder="密码"></el-input>
            </el-form-item>
            <el-form-item style="width:100%;">
                <el-button type="primary" style="width:100%;" @click.native.prevent="handleSubmit" :loading="logining">登录</el-button>
            </el-form-item>
            <el-form-item class="handelButton">
                <el-col :span="24" style="text-align: right;">
                    <el-button style="color: #A4ABB2;" type="text" @click="$router.push('/setPassword')">忘记密码</el-button>
                </el-col>
            </el-form-item>            
            <el-form-item>
                <div class="divider">
                    <!-- <el-button class="button blue" type="text" @click="$router.push('/QuickLogin')">快捷登录</el-button> -->
                    <el-button class="button blue" type="text" @click="$router.push('/QuickLogin')">手机验证登录</el-button>
                </div>
            </el-form-item>
        </el-form>
    </section>
</template>

<script>
  import BrandConfig from '../../config/brand'

  //import NProgress from 'nprogress'
  export default {
    data() {
      return {
        brand: BrandConfig,
        logining: false,
        ruleForm: {
          name: '',
          password: ''
        },
        rules: {
          name: [
            { required: true, message: '请输入账号', trigger: 'blur' },
            //{ validator: validaePass }
          ],
          password: [
            { required: true, message: '请输入密码', trigger: 'blur' },
            //{ validator: validaePass2 }
          ]
        },
        checked: true
      };
    },
    methods: {
      handleReset2() {
        this.$refs.ruleForm.resetFields();
      },
      handleSubmit(ev) {
        var vue = this;
        this.$refs.ruleForm.validate((valid) => {
          // if (valid) {
          //   vue.logining = true;
          //   const companyInfo = {
          //     username: vue.ruleForm.name,
          //     password: vue.$utils.Base64(vue.ruleForm.password)
          //   }
          //   vue.$http.post(vue, '/rest/admin/login', companyInfo,
          //     (vue, data)=> {
          //       vue.logining = false;
          //       vue.$message({
          //         showClose: true,
          //         message: data.message,
          //         type: 'success'
          //       });
          //       vue.getUserInfo()
          //     },
          //     (error, data)=> {
          //       vue.logining = false;
          //      vue.$message({
          //         showClose: true,
          //         message: data.message,
          //         type: 'error'
          //       });
          //     })
          // } else {
          //   console.log('error submit!!');
          //   return false;
          // }
          if (valid) {
            // this.logining = true;
            const user = {
              username: vue.ruleForm.name,
              password: vue.$utils.Base64(vue.ruleForm.password)
            }
            vue.$http.post(vue, '/rest/admin/login', user,
              (vue, data)=> {
                console.log("token="+data.data.token);
                sessionStorage.setItem("token", data.data.token);
                vue.getUserInfo(data.data.token);
              },
              (error, data)=> {
               vue.$message({
                  showClose: true,
                  message: data.message,
                  type: 'error'
                });
              })
          } else {
            console.log('error submit!!');
            return false;
          }          
        });
      },
      getUserInfo(token) {
        let vue = this
        vue.$http.post(vue, '/rest/admin/getLoginAdminInfo', {"token" : token},
          (vue, data)=> {
            let user = data.data
            user.password = vue.ruleForm.password
            vue.checked && sessionStorage.setItem('user', JSON.stringify(user));
            vue.$message({
              showClose: true,
              message: "登录成功",
              type: 'success'
            });              
            vue.$router.push({ path: '/'});
          },
          (error, data)=> {
            
        })
      }
    }
  }

</script>

<style lang="scss" scoped>
  
      .login-container {
        display: inline-block;
        -webkit-border-radius: 18px;
        border-radius: 18px;
        -moz-border-radius: 18px;
        background-clip: padding-box;
        width: 340px;
        padding: 46px 58px 30px;
        background: #fff;
        border: 1px solid rgba(255, 255, 255, 0.36);
        box-shadow: 0 30px 80px rgba(0, 0, 0, 0.42);
        .console-tag {
          margin-bottom: 14px;
          color: #b89555;
          font-size: 10px;
          font-weight: 700;
          letter-spacing: 4px;
        }
        .title {
          margin-bottom: 10px;
          text-align: center;
          color: #111;
          font-size: 28px;
          font-weight: 700;
          line-height: 30px;
        }
        .subtitle {
          margin-bottom: 30px;
          color: #999;
          font-size: 13px;
          letter-spacing: 1px;
        }
        /deep/ .el-input__inner {
          height: 46px;
          border-color: #e6e6e2;
          border-radius: 10px;
          background: #fafaf8;
        }
        /deep/ .el-button--primary {
          height: 46px;
          border-color: #111;
          border-radius: 10px;
          background: #111;
          font-weight: 700;
          letter-spacing: 4px;
        }
        .handelButton {
          text-align: center;
        }
        .divider {
          height: 1px;
          width: 100%;
          margin: 24px 0;
          background-color: #DCDFE6;
          position: relative;
          .button {
            left: 50%;
            -webkit-transform: translateX(-50%) translateY(-50%);
            transform: translateX(-50%) translateY(-50%);
            position: absolute;
            background-color: #FFF;
            padding: 0 20px;
            color: #A4ABB2;
          }
          .blueColor:hover {
            color: #111111;
          }
          .blue {
            color: #111111;
          }
        }
      }
  
  
</style>
