(function () {
  function ready(fn) {
    if (document.readyState !== 'loading') { fn(); }
    else { document.addEventListener('DOMContentLoaded', fn); }
  }

  ready(function () {
    // --- text filter (applies to every overview table) ---
    var filter = document.getElementById('remote-git-filter');
    if (filter) {
      filter.addEventListener('input', function () {
        var q = filter.value.toLowerCase();
        document.querySelectorAll('table.remote-git-sortable tbody tr').forEach(function (tr) {
          tr.style.display = (tr.textContent.toLowerCase().indexOf(q) > -1) ? '' : 'none';
        });
      });
    }

    // --- collapsible archived section ---
    var toggle = document.getElementById('remote-git-archived-toggle');
    var box = document.getElementById('remote-git-archived');
    if (toggle && box) {
      toggle.addEventListener('click', function (e) {
        e.preventDefault();
        var hidden = (box.style.display === 'none');
        box.style.display = hidden ? '' : 'none';
        toggle.classList.toggle('icon-collapsed', !hidden);
        toggle.classList.toggle('icon-expanded', hidden);
      });
    }

    // --- click-to-sort columns ---
    document.querySelectorAll('table.remote-git-sortable th').forEach(function (th, idx) {
      th.classList.add('remote-git-sortable-th');
      th.addEventListener('click', function () {
        var table = th.closest('table');
        var tbody = table.querySelector('tbody');
        var rows = Array.prototype.slice.call(tbody.querySelectorAll('tr'));
        var type = th.getAttribute('data-sort') || 'text';
        var asc = th.getAttribute('data-asc') !== 'true';
        table.querySelectorAll('th').forEach(function (o) {
          o.removeAttribute('data-asc');
          o.classList.remove('sort-asc', 'sort-desc');
        });
        th.setAttribute('data-asc', asc);
        th.classList.add(asc ? 'sort-asc' : 'sort-desc');
        rows.sort(function (a, b) {
          var ca = a.children[idx], cb = b.children[idx];
          var va = ca.getAttribute('data-value'); if (va === null) va = ca.textContent.trim();
          var vb = cb.getAttribute('data-value'); if (vb === null) vb = cb.textContent.trim();
          if (type === 'num') {
            return asc ? (parseFloat(va) || 0) - (parseFloat(vb) || 0)
                       : (parseFloat(vb) || 0) - (parseFloat(va) || 0);
          }
          return asc ? va.localeCompare(vb) : vb.localeCompare(va);
        });
        rows.forEach(function (r) { tbody.appendChild(r); });
      });
    });
  });
})();
