import { shallowMount, createLocalVue } from '@vue/test-utils'
import { expect } from 'chai'
import VueRouter from 'vue-router'
import VueI18n from 'vue-i18n'
import BaseMenuItem from '@/components/BaseMenuItem'
import i18n from '@/plugins/vue-i18n'

const localVue = createLocalVue()
localVue.use(VueRouter)
localVue.use(VueI18n)

describe('BaseMenuItem', () => {
  it('Menu should not render any item when routes are an empty Array', () => {
    const routes = []

    const wrapper = shallowMount(BaseMenuItem, {
      propsData: { routes }
    })

    expect(wrapper.findAll('a').length).to.equal(0)
  })

  it('Menu render all routes (without nested routes)', () => {
    const routes = [
      { label: 'Link 0' },
      { label: 'Link 1' },
      { label: 'Link 2' },
      { label: 'Link 3' }
    ]

    const result = ['Link 0', 'Link 1', 'Link 2', 'Link 3']

    const wrapper = shallowMount(BaseMenuItem, {
      localVue,
      i18n,
      propsData: { routes }
    })

    const links = wrapper.findAll('a')
    expect(links.length).to.equal(4)

    let linkLabels = []
    for (let i = 0; i < links.length; i++) linkLabels.push(links.at(i).text())

    expect(linkLabels).to.deep.equal(result)
  })

  it('Menu render all routes (with nested routes)', () => {
    const routes = [
      { label: 'Link 0' },
      {
        label: 'Title 0',
        routes: [
          { label: 'Link 1' },
          { label: 'Link 2' },
          { label: 'Link 3' },
          {
            label: 'Title 1',
            routes: [
              { label: 'Link 4' },
              { label: 'Link 5' }
            ]
          }
        ]
      },
      { label: 'Link 6' }
    ]

    const wrapper = shallowMount(BaseMenuItem, {
      localVue,
      i18n,
      propsData: { routes }
    })

    expect(wrapper.findAll('a').length).to.equal(2)

    const submenu = wrapper.findAll(BaseMenuItem).at(1)
    expect(submenu.props()).to.deep.equal(routes[1])
  })

  it('Router Link has the right path when using the route\'s name', () => {
    const routes = [
      {
        label: 'Link 0',
        name: 'link-0'
      }
    ]

    const wrapper = shallowMount(BaseMenuItem, {
      localVue,
      i18n,
      propsData: { routes }
    })

    expect(wrapper.find('router-link-stub').props('to')).to.deep.equal({ name: 'link-0' })
  })

  it('Router Link has the right path when using the route\'s path', () => {
    const routes = [
      {
        label: 'Link 0',
        path: 'link-0'
      }
    ]

    const wrapper = shallowMount(BaseMenuItem, {
      localVue,
      i18n,
      propsData: { routes }
    })

    expect(wrapper.find('router-link-stub').props('to')).to.equal('link-0')
  })
})
