<template>
	<el-row class="container">
		<el-col :span="24" class="header">
			<el-col :span="10" class="logo" :class="collapsed?'logo-collapse-width':'logo-width'">
				<span class="brand-monogram">玉</span>
				<span v-if="!collapsed" class="brand-console-name">{{sysName}}</span>
			</el-col>
			<el-col :span="10">
				<div class="tools" @click.prevent="collapse">
					<i class="el-icon-menu"></i>
				</div>
			</el-col>
			<el-col :span="4" class="userinfo">
				<el-dropdown trigger="hover">
					<span class="el-dropdown-link userinfo-inner">
						<span class="avatar-monogram">YK</span>
            			{{sysUserName}}
					</span>
					<el-dropdown-menu slot="dropdown">
						<!-- <el-dropdown-item>我的消息</el-dropdown-item>
						-->
						<el-dropdown-item @click.native="showDialog">修改密码</el-dropdown-item> 
						<el-dropdown-item divided @click.native="logout">退出登录</el-dropdown-item>
					</el-dropdown-menu>
				</el-dropdown>
			</el-col>
		</el-col>
		<el-col :span="24" class="main">
			<aside :class="collapsed?'menu-collapsed':'menu-expanded'">
				<!--导航菜单-->
				<!-- <el-menu :default-active="$route.path" @open="handleopen" @close="handleclose" @select="handleselect"
					 unique-opened router v-if="!collapsed">
					<template v-for="(item,index) in routerArr"  v-if="!item.hidden">
						<el-submenu :key="index" :index="index+''" v-if="!item.leaf">
							<template slot="title"><i :class="item.iconCls"></i>{{item.name}}第一层</template>
							<el-menu-item v-for="child in item.children" :index="child.path" :key="child.path" v-if="!child.hidden">{{child.name}}第二层</el-menu-item>
						</el-submenu>
						<el-menu-item :key="index" v-if="item.leaf&&item.children.length>0" :index="item.children[0].path"><i :class="item.iconCls"></i>{{item.children[0].name}}第一层叶子节点</el-menu-item>
					</template>
				</el-menu> -->

				<el-menu :default-active="$route.path" @open="handleopen" @close="handleclose" @select="handleselect"
					 unique-opened router v-if="!collapsed">
					<template v-for="(item,index) in routerArr"  v-if="!item.hidden">
						<el-submenu :key="index" :index="index+''" v-if="!item.leaf">
							<template slot="title"><i :class="item.iconCls"></i>{{item.name}}</template>
							
							<!-- <el-menu-item v-for="childSecond in item.children" :index="childSecond.path" :key="childSecond.path" v-if="!childSecond.hidden">
								{{childSecond.name}}第二层
							</el-menu-item> -->
						
							<template v-for="(childSecond,index) in item.children"  v-if="!childSecond.hidden">
								<el-submenu :key="index" :index="index+''" v-if="!childSecond.leaf">
									<template slot="title">{{childSecond.name}}</template>
									<el-menu-item v-for="childThird in childSecond.children" :index="childThird.path" :key="childThird.path" v-if="!childThird.hidden">{{childThird.name}}</el-menu-item>
								</el-submenu>
								<el-menu-item :key="index" v-if="childSecond.leaf&&childSecond.children.length>0" :index="childSecond.children[0].path">{{childSecond.children[0].name}}</el-menu-item>
							</template>
						</el-submenu>
						<el-menu-item :key="index" v-if="item.leaf&&item.children.length>0" :index="item.children[0].path"><i :class="item.iconCls"></i>{{item.children[0].name}}</el-menu-item>
					</template>
				</el-menu>

				<!--导航菜单-折叠后-->
				<ul class="el-menu collapsed" v-else ref="menuCollapsed">
					<li v-for="(item,index) in routerArr" :key="index" v-if="!item.hidden" class="el-submenu item">
						<template v-if="!item.leaf">
							<div class="el-submenu__title" style="padding-left: 20px;" @mouseover="showMenu(index,true)" @mouseout="showMenu(index,false)"><i :class="item.iconCls"></i></div>
							<ul class="el-menu submenu" :class="'submenu-hook-'+index" @mouseover="showMenu(index,true)" @mouseout="showMenu(index,false)"> 
								<li v-for="child in item.children" v-if="!child.hidden" :key="child.path" class="el-menu-item" style="padding-left: 40px;" :class="$route.path==child.path?'is-active':''" @click="$router.push(child.path)">{{child.name}}</li>
							</ul>
						</template>
						<template v-else>
							<li class="el-submenu">
								<div class="el-submenu__title el-menu-item" style="padding-left: 20px;height: 56px;line-height: 56px;padding: 0 20px;" :class="$route.path==item.children[0].path?'is-active':''" @click="$router.push(item.children[0].path)"><i :class="item.iconCls"></i></div>
							</li>
						</template>
					</li>
				</ul>
			</aside>
			<section class="content-container">
				<div class="grid-content bg-purple-light">
					<el-col :span="24" class="breadcrumb-container">
						<strong class="title">{{$route.name}}</strong>
						<el-breadcrumb separator="/" class="breadcrumb-inner">
							<el-breadcrumb-item v-for="item in $route.matched" :key="item.path">
								{{ item.name }}
							</el-breadcrumb-item>
						</el-breadcrumb>
					</el-col>
					<el-col :span="24" class="content-wrapper">
						<transition name="fade" mode="out-in">
							<router-view></router-view>
						</transition>
					</el-col>
				</div>
			</section>
		</el-col>
		<el-dialog title="修改密码" class="changePassword" :center="true" :visible.sync="changePasswordForm" @close="closeDialog('passwordForm')" :close-on-click-modal="false">
			<el-form :model="passwordForm" class="changePassform" label-width="150px" :rules="editFormRules" ref="passwordForm">
				<el-form-item label="旧密码：" prop="oldPassword">
					<el-input type="password" v-model="passwordForm.oldPassword" autocomplete="off" placeholder="密码只包含数字、字母组成。"></el-input>
				</el-form-item>
				<el-form-item label="新密码：" prop="newPassword">
					<el-input type="password" v-model="passwordForm.newPassword" autocomplete="off" placeholder="密码只包含数字、字母组成。"></el-input>
				</el-form-item>
			</el-form>
			<div slot="footer" class="dialog-footer">
				<el-button @click.native="changePasswordForm = false">取消</el-button>
				<el-button type="primary" @click.native="passwordSubmit" :loading="logining">提交</el-button>
			</div>
		</el-dialog>
	</el-row>
</template>

<script>
	import BrandConfig from '../config/brand'

	export default {
		data() {
			var checkPassword = (rule, value, callback) => {
                let reg = /^[a-z0-9]+$/i
                if (!reg.test(value)) {
                    if(rule.fullField === 'password') {
                        callback(new Error('密码只包含数字、字母组成。'));
                    } else {
                        callback(new Error('用户名只包含数字、字母组成。'));
                    }
                } else {
                    callback();
                }
            };
			return {
				brand: BrandConfig,
				sysName: BrandConfig.name,
				collapsed:false,
				sysUserName: '',
				sysUserAvatar: '',
				form: {
					name: '',
					region: '',
					date1: '',
					date2: '',
					delivery: false,
					type: [],
					resource: '',
					desc: ''
				},
				changePasswordForm: false,
				passwordForm: {
					oldPassword: '',
					newPassword: ''
				},
				editFormRules: {
					oldPassword: [{ required: true, validator: checkPassword, trigger: 'blur' }],
					newPassword: [{ required: true, validator: checkPassword, trigger: 'blur' }],
				},
				logining: false,
				routerArr: []
			}
		},
		// computed: {
		// 	routerArr() {
		// 		let arr = this.$router.options.routes
		// 		return arr.find(function(ele){
		// 			return ele.menuRole === 'seller'
		// 		})
		// 	}
		// },
		methods: {
			showDialog() {
				this.changePasswordForm = true
			},
			passwordSubmit() {
				let vue = this
				this.$refs.passwordForm.validate((valid) => {
                    if (valid) {
						if(vue.passwordForm.newPassword.length < 6){
							vue.$message({
								showClose: true,
								message: "密码长度最少6位",
								type: 'error'
							});			
							return false;				
						}						
                        vue.logining = true;
                        let param = {
                            oldPassword: vue.$utils.Base64(vue.passwordForm.oldPassword),
                            newPassword: vue.$utils.Base64(vue.passwordForm.newPassword)
                        }
                        vue.$http.post(vue, '/rest/admin/updatePassword', param,
                            (vue, data)=> {
                                vue.logining = false;
                                vue.$message({
                                    showClose: true,
                                    message: data.message,
                                    type: 'success'
                                });
								vue.changePasswordForm = false
								vue.$router.push({ path: '/login'})
                            },
                            (error, data)=> {
                                vue.logining = false;
                                vue.$message({
                                    showClose: true,
                                    message: data.message,
                                    type: 'error'
                                });
                            })
                    }else {
                        console.log('error submit!!');
                        return false;
                    }
                })
			},
			closeDialog(formName) {
                this.$refs[formName].resetFields();
            },
			handleopen() {
				//console.log('handleopen');
			},
			handleclose() {
				//console.log('handleclose');
			},
			handleselect: function (a, b) {
			},
			//退出登录
			logout: function () {
				var vue = this;
				this.$confirm('确认退出吗?', '提示', {
					//type: 'warning'
				}).then(() => {
					vue.$http.post(vue, '/rest/admin/logout', {},
						function(vue, data) {
							sessionStorage.removeItem('user');
							vue.$router.push('/login');
						}, function(error, data) {
							vue.$message({
								showClose: true,
								message: data.message,
								type: 'error'
							});
						}
					)
				}).catch(() => {
				});
			},
			//折叠导航栏
			collapse:function(){
				this.collapsed=!this.collapsed;
			},
			showMenu(i,status){
				this.$refs.menuCollapsed.getElementsByClassName('submenu-hook-'+i)[0].style.display=status?'block':'none';
			},
			formatRouter() {
				let arr = this.$router.options.routes
				return arr.filter(function(ele){
					return ele.menuRole == 'seller'
				})
			}
		},
		mounted() {
			this.routerArr = this.$router.options.routes
			var user = sessionStorage.getItem('user');
			if (user) {
				user = JSON.parse(user);
				this.sysUserName = user.username || '';
				if(user.issaler) {
					this.routerArr = this.formatRouter()
				}
			}
		}
	}

</script>

<style scoped lang="scss">
	.container {
		position: absolute;
		top: 0px;
		bottom: 0px;
		width: 100%;
		.header {
			height: 60px;
			line-height: 60px;
			background: #ffffff;
			color:#111111;
			border-bottom: 1px solid #edf0f2;
			box-shadow: 0 8px 24px rgba(20, 36, 40, 0.06);
			.userinfo {
				text-align: right;
				padding-right: 35px;
				float: right;
				.userinfo-inner {
					cursor: pointer;
					color:#111111;
					.avatar-monogram {
						display: inline-flex;
						align-items: center;
						justify-content: center;
						width: 30px;
						height: 30px;
						margin-left: 12px;
						border: 1px solid #c8f1ec;
						border-radius: 50%;
						background: #e7faf7;
						color: #008f82;
						font-size: 11px;
						font-weight: 700;
						letter-spacing: 1px;
						float: right;
					}
				}
			}
			.logo {
				display: flex;
				align-items: center;
				height:60px;
				box-sizing: border-box;
				font-size: 15px;
				padding-left:14px;
				padding-right:14px;
				border-color: #edf0f2;
				border-right-width: 1px;
				border-right-style: solid;
				.brand-monogram {
					display: inline-flex;
					align-items: center;
					justify-content: center;
					flex: 0 0 34px;
					width: 34px;
					height: 34px;
					margin-right: 10px;
					border-radius: 10px;
					background: #00bfae;
					color: #fff;
					font-weight: 900;
				}
				.brand-console-name {
					overflow: hidden;
					white-space: nowrap;
					text-overflow: ellipsis;
					font-weight: 700;
				}
				.txt {
					color:#111111;
				}
			}
			.logo-width{
				width:230px;
			}
			.logo-collapse-width{
				width:60px
			}
			//头部正方体图标
			.tools{
				padding: 0px 23px;
				width:14px;
				height: 60px;
				line-height: 60px;
				cursor: pointer;
			}
		}
		.main {
			display: flex;
			// background: #324057;
			position: absolute;
				top: 60px; //决定头部的高度
			bottom: 0px;
			overflow: hidden;
			aside {
				flex:0 0 230px;
				width: 230px;
				// position: absolute;
				// top: 0px;
				// bottom: 0px;
					.el-menu{
						height: 100%;
						overflow: auto;
						border-right: none;
						background: #ffffff;
					}
				.collapsed{
					width:60px;
					.item{
						position: relative;
					}
					.submenu{
						position:absolute;
						top:0px;
						left:60px;
						z-index:99999;
						height:auto;
						display:none;
					}

				}
			}
			.menu-collapsed{
				flex:0 0 60px;
				width: 60px;
			}
			.menu-expanded{
				flex:0 0 230px;
				width: 230px;
			}
				.content-container {
					background: #f4f7f8;
				flex:1;
				// position: absolute;
				// right: 0px;
				// top: 0px;
				// bottom: 0px;
				// left: 230px;
				overflow-y: scroll;
					padding: 24px;
				.breadcrumb-container {
					//margin-bottom: 15px;
					.title {
						width: 200px;
						float: left;
						color: #475669;
					}
					.breadcrumb-inner {
						float: right;
					}
				}
					.content-wrapper {
						background-color: #fff;
						box-sizing: border-box;
						border-radius: 14px;
						box-shadow: 0 8px 30px rgba(0, 0, 0, 0.05);
					}
				}
			}
		.changePassword {
			.changePassform {
				margin: 0 auto;
				max-width: 600px;
				.el-input {
					max-width: 400px;
				}
			}
		}

		}
		/deep/ .el-menu-item,
		/deep/ .el-submenu__title {
			color: #536166;
		}
		/deep/ .el-menu-item:focus,
		/deep/ .el-menu-item:hover,
		/deep/ .el-submenu__title:hover {
			color: #111111;
			background: #eefaf8;
		}
		/deep/ .el-menu-item.is-active {
			color: #008f82;
			background: #e7faf7;
			border-right: 3px solid #00bfae;
			font-weight: 700;
		}
</style>
