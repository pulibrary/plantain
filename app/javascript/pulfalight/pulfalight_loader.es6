import Vue from 'vue/dist/vue.esm'
import Vuex from "vuex"
import system from 'lux-design-system'
import "lux-design-system/dist/system/system.css"
import "lux-design-system/dist/system/tokens/tokens.scss"
import store from '../store'
import RequestCart from '../components/RequestCart'
import AddToCartButton from '../components/AddToCartButton'
import CartViewToggle from '../components/CartViewToggle'
import TocBuilder from "../pulfalight/toc.es6"
import LibCalHours from "../pulfalight/lib_cal_hours.es6"

export default class PulfalightLoader {
  run() {
    this.setup_toc()
    this.setup_vue()
    this.setup_lib_cal_hours()
    this.setup_range_limit()
  }

  setup_lib_cal_hours() {
    const elements = document.getElementsByClassName("hours")
    for (var i = 0; i < elements.length; i++) {
      new  LibCalHours(elements[i]).insert_hours()
    }
  }

  setup_range_limit() {
    // Initialize the range limit interface
    $('.blacklight-date_range_sim').data('plot-config', {
          selection: { color: '#C0FF83' },
          colors: ['#ffffff'],
          series: { lines: { fillColor: 'rgba(255,255,255, 0.5)' }},
          grid: { color: '#aaaaaa', tickColor: '#aaaaaa', borderWidth: 0 }
    });
  }

  setup_toc() {
    const toc = new TocBuilder('#toc')
    toc.build()
  }

  setup_vue() {
    Vue.use(system)
    var elements = document.getElementsByClassName("lux")
    for (var i = 0; i < elements.length; i++) {
      new Vue({
        el: elements[i],
        store,
        components: {
          'request-cart': RequestCart,
          'add-to-cart-button': AddToCartButton,
          'cart-view-toggle': CartViewToggle
        }
      })
    }
  }
}
