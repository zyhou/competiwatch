import {on} from 'delegated-events'
import remoteLoadCharts from './remote-load-charts.js'

function activateTab(link, tabContent) {
  const container = link.closest('.js-tab-container')
  const otherLinks = container.querySelectorAll('.js-tab')
  const otherTabContents = container.querySelectorAll('.js-tab-contents')

  for (const otherLink of otherLinks) {
    otherLink.classList.remove('selected')
  }

  for (const otherTabContent of otherTabContents) {
    otherTabContent.classList.add('d-none')
  }

  tabContent.classList.remove('d-none')
  link.classList.add('selected')

  if (link.classList.contains('js-trends-tab')) {
    remoteLoadCharts()
  }

  setTimeout(function() {
    if (typeof container.scrollIntoView === 'function') {
      container.scrollIntoView({ behavior: 'smooth', block: 'start', inline: 'nearest' })
    } else {
      const header = document.querySelector('.js-top-nav')
      window.scroll({ top: header.clientHeight, left: 0, behavior: 'smooth' })
    }
  }, 100)
}

on('click', '.js-tab', function(event) {
  const link = event.currentTarget
  const selector = link.getAttribute('href')
  if (selector && selector.indexOf('#') !== 0) {
    return
  }

  const tabContent = document.querySelector(selector)
  activateTab(link, tabContent)
})

function loadTabFromUrl() {
  const tabID = (window.location.hash || '').replace(/^#/, '')
  const tabContent = document.getElementById(tabID)
  const link = document.querySelector(`.js-tab[href="#${tabID}"]`)
  if (!tabContent || !link) {
    return
  }

  activateTab(link, tabContent)
}
loadTabFromUrl()
