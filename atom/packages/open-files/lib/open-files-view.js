'use babel';

import {requirePackages} from 'atom-utils'
import {CompositeDisposable} from 'atom'
import _ from 'lodash'
import $ from 'jquery'
import OpenFilesPaneView from './open-files-pane-view'

// Polyfill for preprend() (for some reason, preprend itself stopped working in 1.16.0.
// Ideally, this should be changed to not use preprend() at all)
(function (arr) {
  arr.forEach(function (item) {
    if (item.hasOwnProperty('prepend')) {
      return;
    }
    Object.defineProperty(item, 'prepend', {
      configurable: true,
      enumerable: true,
      writable: true,
      value: function prepend() {
        var argArr = Array.prototype.slice.call(arguments),
          docFrag = document.createDocumentFragment();

        argArr.forEach(function (argItem) {
          var isNode = argItem instanceof Node;
          docFrag.appendChild(isNode ? argItem : document.createTextNode(String(argItem)));
        });

        this.insertBefore(docFrag, this.firstChild);
      }
    });
  });
})([Element.prototype, Document.prototype, DocumentFragment.prototype]);

let currentStateKey = null

export default class OpenFilesView {
  constructor(addIconToElement) {
    // Create root element
    this.element = document.createElement('div');
    this.element.classList.add('open-files');
		this.groups = []
		this.paneSub = new CompositeDisposable
    this.addIconToElement = addIconToElement
    let version = atom.getVersion()
    if (+version.split('.')[0] == 1 & +version.split('.')[1] < 17) {
      this.paneSub.add(atom.workspace.observePanes(pane => {
  			this.addTabGroup(pane)
  			let destroySub = pane.onDidDestroy(() => {
  				destroySub.dispose()
  				return this.removeTabGroup(pane)
  			})
  			return this.paneSub.add(destroySub)
  		}))
    } else {
      this.paneSub.add(atom.workspace.getCenter().observePanes(pane => {
        let newStateKey = atom.getStateKey(atom.project.getPaths())
        if (newStateKey !== currentStateKey) {
          currentStateKey = newStateKey
          this.groups.map(group => group.destroy())
          this.groups = []
      		this.paneSub = new CompositeDisposable
        }
        this.addTabGroup(pane)
        let destroySub = pane.onDidDestroy(() => {
          destroySub.dispose()
          this.removeTabGroup(pane)
          setTimeout(() => {
            if (atom.workspace.getCenter().getPanes().length === 1) {
              let title = document.querySelector('.open-files-title')
              title.innerHTML = '<span><strong>OPEN FILES</strong></span>'
            } else if (atom.workspace.getCenter().getPanes().length > 1) {
              let titles = document.querySelectorAll('.open-files-title')
              for (let i = 0; i < titles.length; i++) {
                titles[i].innerHTML = '<span><strong>PANEL #' + (i + 1) + ' - OPEN FILES</strong></span>'
              }
            }
          })
        })
        return this.paneSub.add(destroySub)
      }))
    }
  }

	addTabGroup(pane) {
		let group = new OpenFilesPaneView
    if (this.groups.length === 0) {
      group.setPane(pane, this.addIconToElement, false)
		  this.groups.push(group)
      this.element.appendChild(group.panelRootList)
    } else {
      setTimeout(() => {
        group.setPane(pane, this.addIconToElement, true)
  		  this.groups.push(group)
        this.element.appendChild(group.panelRootList)
        let titles = document.querySelectorAll('.open-files-title')
        for (let i = 0; i < titles.length; i++) {
          titles[i].innerHTML = '<span><strong>PANEL #' + (i + 1) + ' - OPEN FILES</strong></span>'
        }
      }, 1000)
    }
	}

	removeTabGroup(pane) {
		let group = _.findIndex(this.groups, group => group.pane === pane)
		this.groups[group].destroy()
		this.groups.splice(group, 1)
	}
  // Returns an object that can be retrieved when package is activated
  serialize() {}

  // Tear down any state and detach
  destroy() {
    this.element.remove()
		this.paneSub.dispose()
    document.getElementById('foldersLabel').outerHTML = ''
  }

	createOpenFiles(treeView) {
    let treeViewInstance = treeView.getTreeViewInstance()
		let treeViewHeader = document.createElement('div')
		let treeViewHeaderSpan = document.createElement('span')
		let treeViewHeaderSpanStyle = document.createElement('strong')
		treeViewHeaderSpanStyle.innerText = 'FOLDERS'
		treeViewHeaderSpan.appendChild(treeViewHeaderSpanStyle)
		treeViewHeader.appendChild(treeViewHeaderSpan)
    treeViewHeader.setAttribute('id', 'foldersLabel');
		treeViewHeader.style.paddingLeft = '10px'
		treeViewHeader.style.marginTop = '5px'
		treeViewHeader.style.marginBottom = '5px'
    treeViewInstance.element.prepend(treeViewHeader)
    treeViewInstance.element.prepend(this.element)
    treeViewInstance.element.scrollTop
	}
}
