const pptxgen = require('pptxgenjs');
const React = require('react');
const ReactDOMServer = require('react-dom/server');
const sharp = require('sharp');
const fa = require('react-icons/fa');
const fs = require('fs');

const D = JSON.parse(fs.readFileSync('data.json'));
const SAYS = JSON.parse(fs.readFileSync('says.json'));
SAYS[3] = "Bare fields, no government. In the debt village, fourteen people are left after ten years. There is no work for most of them, without work no money, without money no bread. In the SuMSy village almost everyone lives: five units a month is a meal. Same fields, same bakers. Only the money.";
SAYS[6] = "Now firms get owners, and shares that trade. Money in the SuMSy village had been spread almost evenly. With shares the gap between the richest tenth and the poorest tenth more than triples — from about 23 meals to 78. It stays far below the debt village's, where the gap is over 200 meals. So the money system does a lot, but ownership is the other half of the story. Cooperatives take the SuMSy gap back down to about 63.";

const RUST = 'B8541C', GREEN = '2A7F62', INK = '1F1D1A', MUTED = '8A857C', LIGHT = 'FFFFFF', DARK = '1F1D1A';
const HEAD = 'Cambria', BODY = 'Calibri';
const PROVISIONAL = 'data: 24 Sept run — to refresh';

async function icon(Comp, color, size = 256) {
  const svg = ReactDOMServer.renderToStaticMarkup(React.createElement(Comp, { color: '#' + color, size: String(size) }));
  const buf = await sharp(Buffer.from(svg)).png().toBuffer();
  return 'image/png;base64,' + buf.toString('base64');
}
const img = f => 'image/png;base64,' + fs.readFileSync(f).toString('base64');

(async () => {
  const pres = new pptxgen();
  pres.layout = 'LAYOUT_16x9';                       // 10 x 5.625 in
  pres.title = 'A simulated economy – What it takes to survive';

  const title = (s, text, color = INK, y = 0.4) =>
    s.addText(text, { x: 0.6, y, w: 8.8, h: 0.8, fontFace: HEAD, fontSize: 36, bold: true, color, margin: 0, isTextBox: true });
  const tag = s => s.addText(PROVISIONAL, { x: 6.9, y: 5.25, w: 2.8, h: 0.25, fontFace: BODY, fontSize: 9, color: 'B5B0A6', align: 'right', margin: 0, isTextBox: true });
  const big = (s, text, x, y, color, w = 3.5, size = 60) =>
    s.addText(text, { x, y, w, h: 1.0, fontFace: HEAD, fontSize: size, bold: true, color, margin: 0, isTextBox: true });

  // 1 · Two villages
  let s = pres.addSlide(); s.background = { color: DARK };
  s.addText('What it takes to survive', { x: 0.6, y: 0.45, w: 8.8, h: 0.9, fontFace: HEAD, fontSize: 40, bold: true, color: LIGHT, margin: 0, isTextBox: true });
  s.addImage({ data: img('v_debt_dark.png'), x: 0.5, y: 1.65, w: 4.3, h: 2.15 });
  s.addImage({ data: img('v_sumsy_dark.png'), x: 5.2, y: 1.65, w: 4.3, h: 2.15 });
  s.addText('DEBT', { x: 0.5, y: 4.05, w: 4.3, h: 0.5, fontFace: BODY, fontSize: 22, bold: true, color: RUST, align: 'center', charSpacing: 4, margin: 0, isTextBox: true });
  s.addText('SUMSY', { x: 5.2, y: 4.05, w: 4.3, h: 0.5, fontFace: BODY, fontSize: 22, bold: true, color: GREEN, align: 'center', charSpacing: 4, margin: 0, isTextBox: true });
  s.addNotes(SAYS[0]);

  // 2 · Where money comes from
  s = pres.addSlide(); s.background = { color: LIGHT };
  s.addImage({ data: await icon(fa.FaFileSignature, RUST), x: 1.3, y: 0.9, w: 1.6, h: 1.6 });
  s.addImage({ data: await icon(fa.FaCoins, RUST), x: 2.9, y: 1.7, w: 1.0, h: 1.0 });
  s.addImage({ data: await icon(fa.FaCalendarAlt, GREEN), x: 5.8, y: 0.9, w: 1.6, h: 1.6 });
  s.addImage({ data: await icon(fa.FaParking, GREEN), x: 7.4, y: 1.7, w: 1.0, h: 1.0 });
  s.addText('Borrowed into being', { x: 0.6, y: 3.2, w: 4.2, h: 0.7, fontFace: HEAD, fontSize: 28, bold: true, color: RUST, align: 'center', margin: 0, isTextBox: true });
  s.addText('Paid to everyone', { x: 5.2, y: 3.2, w: 4.2, h: 0.7, fontFace: HEAD, fontSize: 28, bold: true, color: GREEN, align: 'center', margin: 0, isTextBox: true });
  s.addNotes(SAYS[1]);

  // 3 · The ladder
  s = pres.addSlide(); s.background = { color: LIGHT };
  const rungs = [fa.FaSeedling, fa.FaLandmark, fa.FaTheaterMasks, fa.FaFileContract, fa.FaChartLine, fa.FaHandshake, fa.FaPiggyBank, fa.FaPercent];
  const top = 0.55, bottom = 5.1, n = rungs.length, step = (bottom - top) / n;
  s.addShape(pres.shapes.RECTANGLE, { x: 1.0, y: top - 0.15, w: 0.08, h: bottom - top + 0.3, fill: { color: 'CFC8BB' }, line: { color: 'CFC8BB' } });
  s.addShape(pres.shapes.RECTANGLE, { x: 2.3, y: top - 0.15, w: 0.08, h: bottom - top + 0.3, fill: { color: 'CFC8BB' }, line: { color: 'CFC8BB' } });
  for (let i = 0; i < n; i++) {
    const y = bottom - (i + 0.5) * step;
    s.addShape(pres.shapes.RECTANGLE, { x: 1.0, y: y, w: 1.38, h: 0.06, fill: { color: 'CFC8BB' }, line: { color: 'CFC8BB' } });
    s.addImage({ data: await icon(rungs[i], i % 2 ? GREEN : RUST), x: 2.75, y: y - 0.2, w: 0.42, h: 0.42 });
  }
  s.addText('One rung at a time', { x: 4.2, y: 2.3, w: 5.3, h: 0.9, fontFace: HEAD, fontSize: 40, bold: true, color: INK, margin: 0, isTextBox: true });
  s.addNotes(SAYS[2]);

  // 4 · Without a government
  s = pres.addSlide(); s.background = { color: LIGHT };
  title(s, 'No government');
  s.addImage({ data: img('v_debt_14.png'), x: 0.5, y: 1.45, w: 4.3, h: 2.15 });
  s.addImage({ data: img('v_sumsy.png'), x: 5.2, y: 1.45, w: 4.3, h: 2.15 });
  big(s, String(D.alive0.debt), 0.5, 3.85, RUST, 4.3); big(s, String(D.alive0.sumsy), 5.2, 3.85, GREEN, 4.3);
  tag(s); s.addNotes(SAYS[3]);

  // 5 · The debt village needs debt
  s = pres.addSlide(); s.background = { color: LIGHT };
  title(s, 'Living on debt');
  const months = D.debt_debt.map((_, i) => ((i + 1) % 12 === 0 ? String((i + 1) / 12) : ''));   // years 1-10
  s.addChart(pres.charts.LINE, [{ name: 'Debt money', labels: months, values: D.debt_debt }, { name: 'SuMSy', labels: months, values: D.debt_sumsy }], {
    x: 0.5, y: 1.3, w: 6.3, h: 3.9, chartColors: [RUST, GREEN], lineSize: 3, lineDataSymbol: 'none', showLegend: false,
    catAxisMajorTickMark: 'none', catAxisLabelColor: MUTED, valAxisLabelColor: MUTED, catAxisLabelFontSize: 10, valAxisLabelFontSize: 10,
    valAxisLabelFormatCode: '#,##0', valGridLine: { color: 'E4DED3', size: 0.5 }, catGridLine: { style: 'none' },
    showCatAxisTitle: true, catAxisTitle: 'year', catAxisTitleColor: MUTED, catAxisTitleFontSize: 10 });
  big(s, Math.round(D.debt_debt[D.debt_debt.length - 1] / 1000) + 'k', 7.0, 2.1, RUST, 2.6, 54);
  s.addText('public debt, year 10', { x: 7.0, y: 3.05, w: 2.6, h: 0.4, fontFace: BODY, fontSize: 14, color: MUTED, margin: 0, isTextBox: true });
  tag(s); s.addNotes(SAYS[4]);

  // 6 · The startup cost
  s = pres.addSlide(); s.background = { color: LIGHT };
  title(s, 'A startup cost');
  s.addChart(pres.charts.LINE, [{ name: 'SuMSy', labels: months, values: D.debt_sumsy }], {
    x: 0.5, y: 1.3, w: 6.3, h: 3.9, chartColors: [GREEN], lineSize: 3, lineDataSymbol: 'none', showLegend: false,
    catAxisMajorTickMark: 'none', catAxisLabelColor: MUTED, valAxisLabelColor: MUTED, catAxisLabelFontSize: 10, valAxisLabelFontSize: 10,
    valAxisLabelFormatCode: '#,##0', valGridLine: { color: 'E4DED3', size: 0.5 }, catGridLine: { style: 'none' },
    showCatAxisTitle: true, catAxisTitle: 'year', catAxisTitleColor: MUTED, catAxisTitleFontSize: 10 });
  big(s, 'Repaid', 7.0, 2.1, GREEN, 2.6, 48);
  s.addText('in every run', { x: 7.0, y: 3.0, w: 2.6, h: 0.4, fontFace: BODY, fontSize: 14, color: MUTED, margin: 0, isTextBox: true });
  tag(s); s.addNotes(SAYS[5]);

  // 7 · Give them shares
  s = pres.addSlide(); s.background = { color: LIGHT };
  title(s, 'Shares widen the gap');
  s.addChart(pres.charts.BAR, [
      { name: 'Debt money', labels: ['Before shares', 'With shares', 'With co-ops'], values: [D.gap['debt_7 '], D.gap['debt_8 '], D.gap.debt_B] },
      { name: 'SuMSy', labels: ['Before shares', 'With shares', 'With co-ops'], values: [D.gap['sumsy_7 '], D.gap['sumsy_8 '], D.gap.sumsy_B] }], {
    x: 0.5, y: 1.3, w: 9.0, h: 3.9, barDir: 'col', barGrouping: 'clustered', chartColors: [RUST, GREEN], showLegend: false,
    showValue: true, dataLabelPosition: 'outEnd', dataLabelFontSize: 14, dataLabelColor: INK, dataLabelFormatCode: '0',
    catAxisLabelColor: INK, catAxisLabelFontSize: 14, valAxisHidden: true, valGridLine: { style: 'none' }, catGridLine: { style: 'none' },
    barGapWidthPct: 60 });
  s.addText('rich–poor gap, in meals', { x: 0.6, y: 1.15, w: 4.0, h: 0.3, fontFace: BODY, fontSize: 12, color: MUTED, margin: 0, isTextBox: true });
  tag(s); s.addNotes(SAYS[6]);

  // 8 · What is land worth?
  s = pres.addSlide(); s.background = { color: LIGHT };
  title(s, 'What is land worth?');
  const tags = [['44', 'debt money', RUST, false], ['1,400', 'SuMSy', GREEN, false], ['49', 'SuMSy + land fee', GREEN, true]];
  for (let i = 0; i < 3; i++) {
    const x = 0.7 + i * 3.0, [num, lab, col, outline] = tags[i];
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y: 1.6, w: 2.6, h: 2.2, rectRadius: 0.15,
      fill: { color: outline ? LIGHT : col }, line: { color: col, width: 3 } });
    s.addShape(pres.shapes.OVAL, { x: x + 1.15, y: 1.78, w: 0.3, h: 0.3, fill: { color: LIGHT }, line: { color: col, width: 2 } });
    s.addText(num, { x, y: 2.3, w: 2.6, h: 0.9, fontFace: HEAD, fontSize: 48, bold: true, color: outline ? col : LIGHT, align: 'center', margin: 0, isTextBox: true });
    s.addText(lab, { x, y: 4.0, w: 2.6, h: 0.4, fontFace: BODY, fontSize: 16, color: INK, align: 'center', margin: 0, isTextBox: true });
  }
  s.addText('months of rent', { x: 0.6, y: 4.6, w: 8.8, h: 0.35, fontFace: BODY, fontSize: 13, color: MUTED, align: 'center', margin: 0, isTextBox: true });
  tag(s); s.addNotes(SAYS[7]);

  // 9 · Make them greedy
  s = pres.addSlide(); s.background = { color: LIGHT };
  title(s, 'Everyone greedy');
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.8, y: 1.55, w: 2.2, h: 0.8, rectRadius: 0.1, fill: { color: RUST }, line: { color: RUST } });
  s.addText('CLOSED', { x: 0.8, y: 1.55, w: 2.2, h: 0.8, fontFace: BODY, fontSize: 24, bold: true, color: LIGHT, align: 'center', valign: 'middle', margin: 0, isTextBox: true });
  s.addImage({ data: await icon(fa.FaSyncAlt, MUTED), x: 3.3, y: 1.65, w: 0.6, h: 0.6 });
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 4.2, y: 1.55, w: 2.2, h: 0.8, rectRadius: 0.1, fill: { color: GREEN }, line: { color: GREEN } });
  s.addText('OPEN', { x: 4.2, y: 1.55, w: 2.2, h: 0.8, fontFace: BODY, fontSize: 24, bold: true, color: LIGHT, align: 'center', valign: 'middle', margin: 0, isTextBox: true });
  big(s, '×50', 7.0, 1.45, INK, 2.6, 54);
  s.addImage({ data: img('v_sumsy.png'), x: 1.6, y: 2.75, w: 5.6, h: 2.8 * 0.95 });
  tag(s); s.addNotes(SAYS[8]);

  // 10 · What it takes to survive
  s = pres.addSlide(); s.background = { color: LIGHT };
  title(s, 'What it takes');
  const col = async (x, color, comps) => { for (let i = 0; i < comps.length; i++) {
      const cx = x + i * 1.35;
      s.addShape(pres.shapes.OVAL, { x: cx, y: 1.7, w: 1.05, h: 1.05, fill: { color }, line: { color } });
      s.addImage({ data: await icon(comps[i], LIGHT), x: cx + 0.24, y: 1.94, w: 0.57, h: 0.57 }); } };
  await col(0.8, RUST, [fa.FaLandmark, fa.FaFileContract]);
  await col(5.2, GREEN, [fa.FaHandHoldingUsd, fa.FaParking, fa.FaSeedling]);
  s.addText('DEBT', { x: 0.8, y: 2.95, w: 2.4, h: 0.4, fontFace: BODY, fontSize: 18, bold: true, color: RUST, charSpacing: 4, margin: 0, isTextBox: true });
  s.addText('SUMSY', { x: 5.2, y: 2.95, w: 3.8, h: 0.4, fontFace: BODY, fontSize: 18, bold: true, color: GREEN, charSpacing: 4, margin: 0, isTextBox: true });
  for (const [i, comp] of [fa.FaChartLine, fa.FaBreadSlice].entries()) {
    const cx = 3.9 + i * 1.35;
    s.addShape(pres.shapes.OVAL, { x: cx, y: 3.75, w: 1.05, h: 1.05, fill: { color: INK }, line: { color: INK } });
    s.addImage({ data: await icon(comp, LIGHT), x: cx + 0.24, y: 3.99, w: 0.57, h: 0.57 });
    if (i === 1) s.addImage({ data: await icon(fa.FaBan, 'E0533A'), x: cx - 0.05, y: 3.7, w: 1.15, h: 1.15 });   // no tax on bread
  }
  s.addText('BOTH', { x: 2.6, y: 4.1, w: 1.1, h: 0.4, fontFace: BODY, fontSize: 18, bold: true, color: INK, charSpacing: 4, margin: 0, isTextBox: true });
  s.addNotes(SAYS[9]);

  // 11 · Break the village
  s = pres.addSlide(); s.background = { color: DARK };
  s.addImage({ data: img('v_debt_dark.png'), x: 0.5, y: 0.6, w: 3.2, h: 1.6 });
  s.addImage({ data: img('v_sumsy_dark.png'), x: 0.5, y: 2.35, w: 3.2, h: 1.6 });
  s.addImage({ data: img('qr.png'), x: 7.1, y: 0.7, w: 2.2, h: 2.2 });
  s.addText('Which rule would you change?', { x: 0.5, y: 4.3, w: 9.0, h: 0.8, fontFace: HEAD, fontSize: 34, bold: true, color: LIGHT, margin: 0, isTextBox: true });
  s.addText('The village is public', { x: 6.6, y: 3.05, w: 3.2, h: 0.4, fontFace: BODY, fontSize: 16, color: 'CFC8BB', align: 'center', margin: 0, isTextBox: true });
  s.addNotes(SAYS[10]);

  await pres.writeFile({ fileName: 'what_it_takes_to_survive.pptx' });
  console.log('written');
})();
