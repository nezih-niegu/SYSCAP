import syscapService from '@/services/syscap-service'
import stubResponses from './stub-responses'

let requestQueue = []

const syscapServiceProxy = new Proxy(syscapService, {
  get (service, method) {
    if (method === 'lastRequest') {
      return requestQueue[requestQueue.length - 1]
    }

    if (method === 'firstRequest') {
      return requestQueue[0]
    }

    if (method === 'requestQueue') {
      return requestQueue
    }

    if (method === 'resetRequests') {
      requestQueue = []
    }

    if (method === 'generateServiceWrapper') {
      return (url, wrapperMethod = 'get') => {
        return (config) => new Promise((resolve, reject) => {
          const data = config.path === ''
            ? stubResponses[url][wrapperMethod]
            : stubResponses[url][config.path][wrapperMethod]

          requestQueue.push({
            method: wrapperMethod,
            url: `${url}/${config.path}`,
            config: config.axiosConfig,
            body: config.body
          })

          resolve({ data })
        })
      }
    }

    return (url, ...args) => new Promise((resolve, reject) => {
      const data = stubResponses[url][method]
      const body = args.length === 2 ? args[0] : null
      const config = args.length === 2 ? args[1] : args[0]

      requestQueue.push({
        url,
        method,
        config,
        body
      })

      resolve({ data })
    })
  },

  set (service, prop, value) {
    if (prop === 'requestQueue') {
      requestQueue = value
    }
  }
})

export default syscapServiceProxy
