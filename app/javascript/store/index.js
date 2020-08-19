import Vue from "vue"
import Vuex from "vuex"
import { cartModule } from "./modules"
import VuexPersist from "vuex-persist"

Vue.use(Vuex)

const vuexPersist = new VuexPersist({
  key: "lux",
  storage: window.localStorage,
})

export default new Vuex.Store({
  modules: {
    counter: counterModule,
    gallery: galleryModule,
    cart: cartModule,
  },
  plugins: [vuexPersist.plugin],
})
