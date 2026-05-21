enum BubbleStyle {
  glass('Glass', 'Frosted blur bubbles'),
  solid('Solid', 'Classic filled bubbles'),
  rounded('Rounded', 'Extra soft corners');

  const BubbleStyle(this.label, this.description);

  final String label;
  final String description;
}
