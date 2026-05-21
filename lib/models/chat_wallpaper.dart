/// Built-in chat backgrounds (procedural — no image assets required).
enum ChatWallpaper {
  aurora('Aurora', 'Animated purple & teal glow'),
  sunset('Sunset', 'Warm orange and pink skies'),
  ocean('Ocean', 'Deep blue wave gradients'),
  forest('Forest', 'Calm green nature tones'),
  midnight('Midnight', 'Starry dark cosmic sky'),
  mesh('Neon Mesh', 'Vivid multi-color mesh blend');

  const ChatWallpaper(this.label, this.description);

  final String label;
  final String description;
}
