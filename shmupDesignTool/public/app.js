const canvas       = document.getElementById('gameArea');
const ctx          = canvas.getContext('2d');
const bulletSelect = document.getElementById('bulletSelect');
const deleteBtn    = document.getElementById('deleteBullet');
const editor       = document.getElementById('editor');
const addContBtn   = document.getElementById('addContainer');
const output       = document.getElementById('output');
const copyBtn      = document.getElementById('copyBtn');

let bullets = [];
let selectedBullet = null;

class Bullet {
  constructor(x, y, id) {
    this.x = x; this.y = y;
    this.id = id;
    this.commands = [];
  }
  draw(ctx) {
    ctx.fillStyle = '#f00';
    ctx.beginPath();
    ctx.arc(this.x, this.y, 5, 0, Math.PI*2);
    ctx.fill();
  }
}

function draw() {
  ctx.clearRect(0,0,canvas.width,canvas.height);
  bullets.forEach(b => b.draw(ctx));
  requestAnimationFrame(draw);
}
draw();

canvas.addEventListener('click', e => {
  const rect = canvas.getBoundingClientRect();
  const x = ((e.clientX - rect.left) * canvas.width)  / rect.width;
  const y = ((e.clientY - rect.top)  * canvas.height) / rect.height;

  selectedBullet = bullets.find(b => Math.hypot(b.x - x, b.y - y) < 6);
  if (!selectedBullet) {
    const id = bullets.length + 1;
    selectedBullet = new Bullet(x, y, id);
    bullets.push(selectedBullet);
    const opt = document.createElement('option');
    opt.value = id;
    opt.text  = `Bullet ${id}`;
    bulletSelect.appendChild(opt);
  }
  bulletSelect.value = selectedBullet.id;
  renderEditor();
});

deleteBtn.addEventListener('click', () => {
  if (!selectedBullet) return;
  bullets = bullets.filter(b => b !== selectedBullet);
  bulletSelect.innerHTML = '<option value="">— Select Bullet —</option>';
  bullets.forEach(b => {
    const opt = document.createElement('option');
    opt.value = b.id;
    opt.text  = `Bullet ${b.id}`;
    bulletSelect.appendChild(opt);
  });
  selectedBullet = null;
  renderEditor();
  generateOutput();
});

bulletSelect.addEventListener('change', () => {
  const id = Number(bulletSelect.value);
  selectedBullet = bullets.find(b => b.id === id) || null;
  renderEditor();
});

// Render the command containers, now with delete buttons
function renderEditor() {
  editor.innerHTML = '';
  if (!selectedBullet) return;

  selectedBullet.commands.forEach((cmd, idx) => {
    const div = document.createElement('div');
    div.className = 'command-container';

    ['x','y','time'].forEach(field => {
      const inp = document.createElement('input');
      inp.type = 'number';
      inp.value = cmd[field] ?? 0;
      inp.placeholder = field;
      inp.addEventListener('change', () => {
        cmd[field] = parseFloat(inp.value) || 0;
        generateOutput();
      });
      div.appendChild(inp);
    });

    // Easing dropdown (string options)
    const easingOpts = ["linear","easeInQuad","easeOutQuad","easeInOutQuad"];
    const sel = document.createElement('select');
    easingOpts.forEach(optName => {
      const opt = document.createElement('option');
      opt.value = optName;
      opt.text  = optName;
      if (cmd.ease === optName) opt.selected = true;
      sel.appendChild(opt);
    });
    sel.addEventListener('change', () => {
      cmd.ease = sel.value;
      generateOutput();
    });
    div.appendChild(sel);

    // Rate input
    const rateInp = document.createElement('input');
    rateInp.type = 'number';
    rateInp.value = cmd.rate ?? 0;
    rateInp.placeholder = 'rate';
    rateInp.addEventListener('change', () => {
      cmd.rate = parseFloat(rateInp.value) || 0;
      generateOutput();
    });
    div.appendChild(rateInp);

    // Delete‑container button
    const del = document.createElement('button');
    del.textContent = '×';
    del.className   = 'delete-container-btn';
    del.addEventListener('click', () => {
      selectedBullet.commands.splice(idx, 1);
      renderEditor();
      generateOutput();
    });
    div.appendChild(del);

    editor.appendChild(div);
  });
}

addContBtn.addEventListener('click', () => {
  if (!selectedBullet) {
    alert('Select a bullet first');
    return;
  }
  selectedBullet.commands.push({ x:0,y:0,time:0,ease:'linear',rate:0 });
  renderEditor();
  generateOutput();
});

function generateOutput() {
  const lines = [];
  bullets.forEach(b => {
    lines.push(`// Bullet ${b.id} @ (${b.x.toFixed(1)},${b.y.toFixed(1)})`);
    b.commands.forEach(c => {
      lines.push(`MoveBy(${c.time}, ${c.x}, ${c.y}, "${c.ease}", ${c.rate});`);
    });
  });
  output.value = lines.join('\n');
}

copyBtn.addEventListener('click', () => {
  navigator.clipboard.writeText(output.value)
    .then(() => {
      copyBtn.textContent = 'Copied!';
      setTimeout(()=>copyBtn.textContent='Copy', 1500);
    });
});

// initialize
renderEditor();
generateOutput();
