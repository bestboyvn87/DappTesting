import BaseService from '../model/BaseService'
import _ from 'lodash'
import Tx from 'ethereumjs-tx'
const SolidityFunction = require('web3/lib/web3/function')
import {WEB3} from '@/constant'

export default class extends BaseService {
    async getFund() {
        const storeUser = this.store.getState().user
        let {contract} = storeUser.profile
        if (!contract || contract.fund().toString() == 0) {
          return 0
        }
        return contract.fund().toString() / 1e18
    }

    async getFundBonus() {
        const storeUser = this.store.getState().user
        let {contract} = storeUser.profile
        if (!contract || contract.fundBonus().toString() == 0) {
          return 0
        }
        return contract.fundBonus().toString() / 1e18
    }
}
