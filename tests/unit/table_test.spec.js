import { expect } from 'chai'
import { createLocalVue, shallowMount, mount } from '@vue/test-utils'
import flushPromises from 'flush-promises'
import SyscapServiceProxy from '../stubs/api-service'
import SysTable from '@/components/SysTable'
import VueRouter from 'vue-router'
import VueI18n from 'vue-i18n'
import VueProgressBar from 'vue-progressbar'
import vueDebounce from 'vue-debounce'
import i18n from '@/plugins/vue-i18n'
import Buefy from '@/plugins/buefy'

// FONT AWESOME
import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome'
import registerIcons from '@/fa-icons'

// FONT AWESOME REGISTRATION
registerIcons()

// CREATE LOCALVUE
const localVue = createLocalVue()

// GLOBAL COMPONENTS REGISTRATION
localVue.use(VueProgressBar, {
  color: '#D2A862',
  failedColor: '#FF7052',
  height: '3px'
})
localVue.use(VueRouter)
localVue.use(VueI18n)
localVue.use(vueDebounce)
localVue.component('fai', FontAwesomeIcon)
localVue.use(Buefy)

// MIXINS
require('@/mixins')

// DEFINE TESTS VARIABLES
const headers = [
  { label: 'Column 1', key: 'column_1' },
  { label: 'Column 2', key: 'column_2' },
  { label: 'Column 3', key: 'column_3' },
  { label: 'Column 4', key: 'column_4' }
]

const rows = [
  {
    column_1: 'Something 1',
    column_2: 'Something 2',
    column_3: 'Something 3',
    column_4: 'Something 4'
  }
]

let multipleRows = []
for (var i = 0; i < 100; i++) multipleRows.push(rows[0])

const promoterHeaders = [
  {
    label: 'Id',
    key: 'id'
  },
  {
    label: 'First name',
    key: 'name'
  },
  {
    label: 'Last name',
    key: 'lastname'
  },
  {
    label: 'Matri name',
    key: 'matriname'
  },
  {
    label: 'Base Commission',
    key: 'base_commission'
  }
]

// UNIT TESTS
describe('SysTable', () => {
  it('table should render default headers', () => {
    const wrapper = shallowMount(SysTable, {
      propsData: {
        headers,
        rows
      },
      localVue,
      i18n
    })

    const renderedHeaders = wrapper.find('thead').findAll('th')

    headers.forEach((header, key) => {
      expect(header.label).to.equal(renderedHeaders.at(key).text())
    })
  })

  it('table should render default rows', () => {
    const wrapper = mount(SysTable, {
      propsData: {
        headers,
        rows
      },
      localVue,
      i18n
    })

    const renderedRows = wrapper.findAllComponents({ name: 'VDefaultColumn' })

    headers.forEach((header, key) => {
      expect(rows[0][header.key]).to.equal(renderedRows.at(key).text())
    })
  })

  it('table render pagination', () => {
    const wrapper = shallowMount(SysTable, {
      propsData: {
        headers,
        rows: multipleRows
      },
      localVue,
      i18n
    })

    const pages = wrapper.find('nav.pagination > ul').findAll('li > a')

    expect(pages.length).to.equal(9)
  })

  it('table can change current page', async () => {
    const wrapper = shallowMount(SysTable, {
      propsData: {
        headers,
        rows: multipleRows
      },
      localVue,
      i18n
    })
    let pages = wrapper.find('nav.pagination > ul').findAll('li > a')

    expect(pages.at(0).classes()).to.include('is-current')
    await pages.at(1).trigger('click')
    pages = wrapper.find('nav.pagination > ul').findAll('li > a')
    expect(pages.length).to.equal(11)
    expect(pages.at(2).classes()).to.not.include('is-current')
    expect(pages.at(3).classes()).to.include('is-current')
  })

  it('table pagination should changed to page 1 when rows per page value changes', async () => {
    const wrapper = shallowMount(SysTable, {
      propsData: {
        headers,
        rows: multipleRows
      },
      localVue,
      i18n
    })

    let pages = wrapper.find('nav.pagination > ul').findAll('li > a')
    await pages.at(1).trigger('click')

    const rowsPerPage = wrapper.find('.rows-per-page > .select > select').findAll('option')
    await rowsPerPage.at(3).setSelected()

    pages = wrapper.find('nav.pagination > ul').findAll('li > a')
    expect(pages.length).to.equal(4)
    expect(pages.at(0).classes()).to.include('is-current')
  })

  it('table calls service on Create if service is set', () => {
    shallowMount(SysTable, {
      propsData: {
        headers,
        service: SyscapServiceProxy.generateServiceWrapper('promoters')
      },
      localVue,
      i18n
    })

    const request = SyscapServiceProxy.lastRequest

    expect(request.url).to.equal('promoters/')
    expect(request.method).to.equal('get')
    expect(request.config.params).to.deep.equal({ order_by: '',
      order: '',
      page: 1,
      per: 10
    })
  })

  it('table calls widget endpoint on Create if widget list is set', () => {
    shallowMount(SysTable, {
      propsData: {
        headers,
        service: SyscapServiceProxy.generateServiceWrapper('promoters'),
        widgetsList: { count: true }
      },
      localVue,
      i18n
    })

    const request = SyscapServiceProxy.lastRequest

    expect(request.url).to.equal('promoters/widgets')
    expect(request.method).to.equal('get')
    expect(request.config.params.widgets).to.deep.equal({ count: true })
  })

  it('table calls service when paginations changes', async () => {
    const wrapper = shallowMount(SysTable, {
      propsData: {
        headers: promoterHeaders,
        service: SyscapServiceProxy.generateServiceWrapper('promoters')
      },
      localVue,
      i18n
    })

    await flushPromises()
    SyscapServiceProxy.resetRequests

    await wrapper.find('nav > ul').findAll('li > a').at(1).trigger('click')
    await wrapper.find('.rows-per-page > .select > select').findAll('option').at(0).setSelected()

    await flushPromises()

    let request = SyscapServiceProxy.firstRequest

    expect(request.url).to.equal('promoters/')
    expect(request.method).to.equal('get')
    expect(request.config.params).to.deep.equal({
      order_by: '',
      order: '',
      page: 2,
      per: 10
    })

    request = SyscapServiceProxy.lastRequest

    expect(request.url).to.equal('promoters/')
    expect(request.method).to.equal('get')
    expect(request.config.params).to.deep.equal({
      order_by: '',
      order: '',
      page: 1,
      per: '5'
    })
  })
})
