export const defaultAllowedTags = [
  'address', 'article', 'aside', 'footer', 'header',
  'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'hgroup',
  'main', 'nav', 'section',
  'blockquote', 'dd', 'div', 'dl', 'dt',
  'figcaption', 'figure', 'hr', 'li', 'ol', 'p', 'pre', 'ul',
  'a', 'abbr', 'b', 'bdi', 'bdo', 'br', 'cite', 'code',
  'data', 'dfn', 'em', 'i', 'img', 'kbd', 'mark', 'q',
  'rb', 'rp', 'rt', 'rtc', 'ruby',
  's', 'samp', 'small', 'span', 'strong', 'sub', 'sup',
  'time', 'u', 'var', 'wbr',
  'caption', 'col', 'colgroup', 'table', 'tbody', 'td', 'tfoot', 'th', 'thead', 'tr',
]

export const defaultAllowedAttributes: Record<string, string[]> = {
  a: ['href', 'name', 'target'],
  span: ['class'],
  pre: ['class'],
  code: ['class'],
  img: ['src', 'alt', 'title', 'width', 'height', 'loading'],
}
