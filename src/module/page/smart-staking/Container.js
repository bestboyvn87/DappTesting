import {createContainer} from '@/util'
import Component from './Component'
import ContractService from '@/service/ContractService'
import UserService from '@/service/UserService'

export default createContainer(Component, (state) => {
    return {
        ...state.user
    }
}, () => {
    const contractService = new ContractService()
    const userService = new UserService()

    return {
        async getFundBonus() {
            return await contractService.getFundBonus()
        },
        async deposit(packageId, amount) {
            return await contractService.deposit(packageId, amount)
        },
        async getBalance(packageId, amount) {
            return await userService.getBalance()
        },
        async callFunction(functionName, params) {
            return await contractService.callFunction(functionName, params)
        },
        getEventDepositRewardPool() {
            return contractService.getEventDepositRewardPool()
        }        
    }
})
