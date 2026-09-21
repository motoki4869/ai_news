const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const vm = require('node:vm');

const TERM_LINK = fs.readFileSync(
  path.join(__dirname, '..', 'history', 'term-link.js'),
  'utf8',
);

class FakeNode {
  constructor(nodeType, textContent = '') {
    this.nodeType = nodeType;
    this.textContent = textContent;
    this.parentNode = null;
  }

  replaceWith(node) {
    const siblings = this.parentNode.childNodes;
    const index = siblings.indexOf(this);
    const replacements = node.nodeType === 11 ? node.childNodes : [node];
    replacements.forEach(child => { child.parentNode = this.parentNode; });
    siblings.splice(index, 1, ...replacements);
  }
}

class FakeElement extends FakeNode {
  constructor(tagName) {
    super(1);
    this.tagName = tagName.toUpperCase();
    this.childNodes = [];
    this.dataset = {};
    this.className = '';
    this.href = '';
  }

  appendChild(child) {
    child.parentNode = this;
    this.childNodes.push(child);
    return child;
  }

  addEventListener() {}

  get textContent() {
    return this.childNodes.map(child => child.textContent).join('');
  }

  set textContent(value) {
    this.childNodes = value === '' ? [] : [new FakeNode(3, value)];
  }

  querySelectorAll(selector) {
    return selector === '.news-card p, .news-card .point-list li' ? [this] : [];
  }
}

class FakeFragment extends FakeNode {
  constructor() {
    super(11);
    this.childNodes = [];
  }

  appendChild(child) {
    child.parentNode = this;
    this.childNodes.push(child);
    return child;
  }
}

function runLinkifier(text) {
  const target = new FakeElement('p');
  target.appendChild(new FakeNode(3, text));
  const window = {
    GLOSSARY: [{
      entries: [
        { term: '<strong>DI（意思決定知能）</strong>' },
        { term: '<strong>MCP</strong>' },
        { term: '<strong>RAG</strong>' },
      ],
    }],
  };
  const document = {
    createDocumentFragment: () => new FakeFragment(),
    createTextNode: value => new FakeNode(3, value),
    createElement: tagName => new FakeElement(tagName),
  };
  const context = {
    window,
    document,
    Node: { ELEMENT_NODE: 1, TEXT_NODE: 3 },
    encodeURIComponent,
  };
  vm.runInNewContext(TERM_LINK, context);
  window.linkifyGlossaryTerms(target);
  return target.childNodes
    .filter(node => node.nodeType === 1)
    .map(node => ({ text: node.textContent, className: node.className, href: node.href }));
}

test('用語集の括弧内別名と2文字のDIを含め、本文中の全用語をリンク化する', () => {
  const links = runLinkifier('意思決定知能(DI) と MCP、RAG');

  assert.deepEqual(links.map(link => link.text), ['意思決定知能', 'DI', 'MCP', 'RAG']);
  assert.ok(links.every(link => link.className === 'gloss-link'));
});
