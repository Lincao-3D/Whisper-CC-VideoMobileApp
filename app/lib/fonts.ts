import RNFS from 'react-native-fs';

export async function listUserFonts(): Promise<string[]> {
  const dir = `${RNFS.DocumentDirectoryPath}/fonts`;
  try {
    const items = await RNFS.readDir(dir);
    return items.filter(f => f.isFile() && /\.(ttf|otf)$/i.test(f.name)).map(f => f.path);
  } catch {
    return [];
  }
}