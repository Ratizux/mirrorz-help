const { readFileSync } = require('fs');

const FRONT_MATTER_REGEX = /---([\s\S]*?)---/;
const FRONT_MATTER_TITLE_REGEX = /title: (.+)/;
const CODEBLOCK_REGEX = /\<[\s\r\n]*?CodeBlock([\s\S]*?)\>[\s\S]*?```(\w*)[\r\n]([\s\S]*?)```[\s\S]*?\<\/CodeBlock\>/;
const MENU_REGEX = /menus={([\s\S]*)}/;

function extract_front_matter(mdx) {
  const front_matter = mdx.match(FRONT_MATTER_REGEX)
  if (front_matter !== null) {
    const title = front_matter[1].match(FRONT_MATTER_TITLE_REGEX);
    if (title === null) {
      console.error("Front matter invalid!");
      process.exit(1);
    }
    return [{
      title,
    }, mdx.substring(front_matter.index + front_matter[0].length)]
  } else {
    console.error("No front matter found!");
    process.exit(1);
  }
  return parts;
}

function extract_codeblock(mdx) {
  const parts = [];
  let index = 0;
  while (index != mdx.length) {
    const codeblock = mdx.substring(index).match(CODEBLOCK_REGEX)
    if (codeblock !== null) {
      const md = mdx.substring(index, index + codeblock.index);
      parts.push(md);

      const menu = codeblock[1].match(MENU_REGEX);
      if (menu !== null) {
        // FIXME: it is not valid json so we can not use JSON.parse
        menu_arr = eval('(' + menu[1] + ')');
        //console.log(menu_arr);
        codeblock.menu = menu_arr;
      }
      parts.push(codeblock);
      index += codeblock.index + codeblock[0].length;
    } else {
      const md = mdx.substring(index);
      parts.push(md);
      index = mdx.length;
    }
  }
  return parts;
}

function tunaify_front_matter(front_matter, content_num) {
  let target_ids = "";
  for (let i = 0; i != content_num; ++i) {
    if (i != 0) {
      target_ids += ','
    }
    target_ids += `#content-${i}`;
  }
  const result = `---
category: help
layout: help
mirrorid: ${process.argv[3]}
---

# ${front_matter.title[1]}

<form class="form-inline">
<div class="form-group">
	<label>是否使用 HTTPS</label>
	<select id="http-select" class="form-control content-select" data-target="${target_ids}">
	  <option data-http_protocol="https://" selected>是</option>
	  <option data-http_protocol="http://">否</option>
	</select>
</div>
</form>


<form class="form-inline">
<div class="form-group">
	<label>是否使用 sudo</label>
	<select id="sudo-select" class="form-control content-select" data-target="${target_ids}">
	  <option data-sudo="sudo " selected>是</option>
	  <option data-sudo="">否</option>
	</select>
</div>
</form>
`;
  return result;
}

function tunaify_menu_item(menu_item, select_index, content_index) {
  let result = ""
  const form_before = `
<form class="form-inline">
<div class="form-group">
`;
  result += form_before;
  const label = 
`  <label>${menu_item.title}：</label>
`;
  result += label;
  const select_before =
`    <select id="select-${content_index}-${select_index}" class="form-control content-select" data-target="#content-${content_index}">
`;
  result += select_before;
  menu_item.items.forEach((e, i) => {
    const option_before = 
`      <option`;
    result += option_before;
    const dict = e[1];
    for (key in dict) {
      result += ` data-${key}="${dict[key]}"`;
    }
    if (i == 0) {
      result += ' selected';
    }
    const display = e[0];
    result += `>${display}</option>
`;
  })
  const select_after =
`    </select>`;
  result += select_after;
  const form_after = `
</div>
</form>
`;
  result += form_after;
  return result;
}

function tunaify_menu(codeblock, content_index) {
  let result = "";
  if ("menu" in codeblock) {
    codeblock.menu.forEach((e, i) => {
      result += tunaify_menu_item(e, i, content_index);
    })
  }
  return result;
}

function tunaify_template(codeblock, content_index) {
  let result = "";
  let before = `
{% raw %}
<script id="template-${content_index}" type="x-tmpl-markup">
`;
  result += before;
  result += codeblock[3];
  let after = `</script>
{% endraw %}

<p></p>
`;
  result += after;
  return result;
}

function tunaify_target(codeblock, content_index, select_num) {
  let select_ids = "";
  for (let i = 0; i != select_num; ++i) {
    select_ids += `,#select-${content_index}-${i}`;
  }
  let language = codeblock[2] === "" ? "plaintext" : codeblock[2];
  let result = `
<pre>
<code id="content-${content_index}" class="language-${language}" data-template="#template-${content_index}" data-select="#http-select,#sudo-select${select_ids}">
</code>
</pre>`;
  return result;
}

function tunaify(codeblock, content_index) {
  return tunaify_menu(codeblock, content_index)
    + tunaify_template(codeblock, content_index)
    + tunaify_target(codeblock, content_index,
        codeblock.menu ? codeblock.menu.length : 0);
}

if (process.argv.length < 4) {
  console.error("Usage: node transpiler.js input_mdx tuna_name")
  console.exit(1)
}

let mdx = readFileSync(process.argv[2], "utf8");

const [front_matter, mdx_content] = extract_front_matter(mdx)

const parts = extract_codeblock(mdx_content)

let content_num = 0;

for (part of parts) {
  if (typeof part !== 'string') {
    content_num += 1;
  }
}

console.log(tunaify_front_matter(front_matter, content_num));

let content_index = 0;

for (part of parts) {
  if (typeof part === 'string') {
    console.log(part);
  } else {
    console.log(tunaify(part, content_index++));
  }
}
