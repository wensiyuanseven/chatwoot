module.exports = {
  globDirectory: 'public/',//要扫描的根目录。通常是静态资源存放目录。
  globPatterns: ['**/*.{png,ico}'],// 匹配的文件模式，支持多种静态资源类型，**/*.{png,ico} 表示递归查找 public/ 目录下的 .png 和 .ico 文件
  swDest: 'public/sw.js', //生成的 Service Worker 文件存放路径。
};
