import { RNFFmpeg } from 'react-native-ffmpeg';
import RNFS from 'react-native-fs';

export async function burnSubtitles(
  inputVideo: string,
  srtPath: string,
  outputPath: string
) {
  const exists = await RNFS.exists(srtPath);
  if (!exists) {
    throw new Error(`SRT file not found: ${srtPath}`);
  }

  // Escape single quotes for FFmpeg filter safety
  const escapedSrtPath = srtPath.replace(/'/g, "'\\''");

  // Common subtitles filter
  const subtitlesFilter = `subtitles='${escapedSrtPath}':force_style='FontName=Arial,FontSize=24,PrimaryColour=&H00FFFF00&'`;

  // Try hardware‑accelerated encode first
  const hwCmd = [
    `-hwaccel mediacodec`,
    `-i "${inputVideo}"`,
    `-vf "${subtitlesFilter}"`,
    `-c:v h264_mediacodec`,
    `-c:a copy`,
    `"${outputPath}"`
  ].join(' ');

  let { rc } = await RNFFmpeg.execute(hwCmd);

  if (rc !== 0) {
    // Fallback to software if hardware encoding fails
    console.warn('Hardware acceleration failed or unsupported, falling back to software…');

    const swCmd = [
      `-i "${inputVideo}"`,
      `-vf "${subtitlesFilter}"`,
      `-c:v libx264`,    // software x264 encoder
      `-preset ultrafast`,
      `-c:a copy`,
      `"${outputPath}"`
    ].join(' ');

    ({ rc } = await RNFFmpeg.execute(swCmd));
    if (rc !== 0) {
      throw new Error(`FFmpeg failed in both hardware and software modes. rc=${rc}`);
    }
  }

  return outputPath;
}
