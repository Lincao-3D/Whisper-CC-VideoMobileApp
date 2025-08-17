export type CaptionItem = {
  index: number;
  startMs: number;
  endMs: number;
  text: string;
};

function toTimecode(ms: number) {
  const h = Math.floor(ms / 3600000);
  const m = Math.floor((ms % 3600000) / 60000);
  const s = Math.floor((ms % 60000) / 1000);
  const ms3 = Math.floor(ms % 1000);
  const pad = (n: number, w = 2) => n.toString().padStart(w, '0');
  return `${pad(h)}:${pad(m)}:${pad(s)},${pad(ms3, 3)}`;
}

function fromTimecode(tc: string) {
  const m = tc.trim().match(/(\d{2}):(\d{2}):(\d{2}),(\d{3})/);
  if (!m) throw new Error(`Bad timecode: ${tc}`);
  const [_, hh, mm, ss, mmm] = m;
  return (
    parseInt(hh, 10) * 360000