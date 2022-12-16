import { expect } from 'chai'
import store from '@/store/index'

// ----------- LOGIN DATA -----------
// User:
const user = {
  email: 'dev@test.com',
  firstname: 'Dev',
  lastname: 'Test'
}

// Token:
const session = {
  'sub': '1',
  'scp': 'user',
  'aud': null,
  'iat': Date.now() / 1000,
  'exp': Date.now() / 1000 + 600,
  'jti': '53780e7b-029b-42b6-992e-5a8cd5e83da4'
}
const token = btoa('header') + '.' + btoa(JSON.stringify(session)) + '.' + 'secret'

// ----------- LOGIN DATA - END -----------

// -------------- UNIT TEST ---------------
describe('Store Login/Logout', () => {
  it('islogged turns true when a user login', () => {
    expect(store.getters.isLogged).to.be.false

    store.dispatch('signin', { token, user })

    expect(store.getters.isLogged).to.be.true
  })

  it('Store contains user information', () => {
    store.dispatch('signin', { token, user })

    expect(store.getters.getUser).to.deep.equal(user)
  })

  it('isLogged changes to false if user logout', () => {
    store.dispatch('signin', { token, user })
    store.dispatch('logout')

    expect(store.getters.isLogged).to.be.false
  })

  it('Store reset user information after logout', () => {
    store.dispatch('signin', { token, user })
    store.dispatch('logout')

    expect(store.getters.getUser).to.be.null
  })
})
