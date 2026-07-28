<template>
  <div class="login-content">
    <div class="brand-signature">
      <div class="brand-name">{{ brand.name }}</div>
      <div class="brand-en">{{ brand.nameEn }}</div>
    </div>
    <div class="login-center">
      <transition name="fade" mode="out-in">
        <router-view></router-view>
      </transition>
    </div>
    <div class="login-footnote">SMART RESTAURANT OPERATING SYSTEM</div>
  </div>
</template>

<script>
  import BrandConfig from '../config/brand'

  export default {
    data() {
      return {
        brand: BrandConfig
      }
    }
  }
</script>

<style lang="scss" scoped>
  .login-content {
    height:100%;
    overflow: auto;
    background:
      radial-gradient(circle at 18% 20%, rgba(184, 149, 85, 0.18), transparent 28%),
      radial-gradient(circle at 82% 78%, rgba(255, 255, 255, 0.08), transparent 24%),
      #0b0b0b;
    width: 100%;
    position: relative;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    box-sizing: border-box;
    padding: 48px 24px;
    .brand-signature {
      margin-bottom: 34px;
      color: #fff;
      text-align: center;
      .brand-name {
        font-size: 34px;
        font-weight: 800;
        letter-spacing: 5px;
      }
      .brand-en {
        margin-top: 10px;
        color: #b89555;
        font-size: 11px;
        letter-spacing: 8px;
      }
    }
    .login-center {
      margin: 0 auto;
      text-align: center;
    }
    .login-footnote {
      position: absolute;
      bottom: 28px;
      color: rgba(255, 255, 255, 0.28);
      font-size: 10px;
      letter-spacing: 4px;
    }
  }
</style>
