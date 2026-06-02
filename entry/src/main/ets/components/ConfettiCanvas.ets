// components/ConfettiCanvas.ets
// 撒花/彩带动画效果

interface Particle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  color: string;
  size: number;
  rotation: number;
  rotationSpeed: number;
}

@Component
export struct ConfettiCanvas {
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  @State private particles: Particle[] = [];
  private timerId: number = -1;
  private colors: string[] = ['#6B5CE7', '#FF6B9D', '#FFD93D', '#6BCB77', '#4D96FF', '#FF9F45'];

  aboutToAppear(): void {
    this.initParticles();
  }

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
    }
  }

  private initParticles(): void {
    const list: Particle[] = [];
    for (let i = 0; i < 60; i++) {
      list.push({
        x: Math.random() * 300 + 50,
        y: Math.random() * -200 - 50,
        vx: (Math.random() - 0.5) * 4,
        vy: Math.random() * 3 + 2,
        color: this.colors[Math.floor(Math.random() * this.colors.length)],
        size: Math.random() * 8 + 4,
        rotation: Math.random() * 360,
        rotationSpeed: (Math.random() - 0.5) * 10,
      });
    }
    this.particles = list;
  }

  private startAnimation(): void {
    const ctx = this.canvasContext;
    let frameCount = 0;
    // Canvas 组件固定尺寸 400x200，使用固定值绘制
    const width = 400;
    const height = 200;
    this.timerId = setInterval(() => {
      ctx.clearRect(0, 0, width, height);

      let activeCount = 0;
      for (const p of this.particles) {
        p.x += p.vx;
        p.y += p.vy;
        p.vy += 0.05;
        p.rotation += p.rotationSpeed;

        if (p.y < height + 20) {
          activeCount++;
          ctx.save();
          ctx.translate(p.x, p.y);
          ctx.rotate(p.rotation * Math.PI / 180);
          ctx.fillStyle = p.color;
          ctx.fillRect(-p.size / 2, -p.size / 2, p.size, p.size);
          ctx.restore();
        }
      }

      frameCount++;
      if (activeCount === 0 || frameCount > 300) {
        clearInterval(this.timerId);
        this.timerId = -1;
      }
    }, 16);
  }

  build() {
    Canvas(this.canvasContext)
      .width('100%')
      .height(200)
      .backgroundColor(Color.Transparent)
      .onReady(() => {
        this.startAnimation();
      })
  }
}
