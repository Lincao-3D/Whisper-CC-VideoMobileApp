import { RNFFmpeg } from 'react-native-ffmpeg';
import RNFS from 'react-native-fs';

export async function burnSubtitles(inputVideo: string, srtPath: string, outputPath: string) {
  const exists = await RNFS.exists(srtPath);
  if (!exists) throw new Error("SRT file not found: " + srtPath);

  const cmd = `-i "${inputVideo}" -vf subtitles='${srtPath}:force_style=FontName=Arial,FontSize=24,PrimaryColour=&H00FFFF00&' -c:a copy "${outputPath}"`;

  const { rc } = await RNFFmpeg.execute(cmd);
  if (rc !== 0) throw new Error(`FFmpeg failed with rc=${rc}`);
  
  return outputPath;
}
