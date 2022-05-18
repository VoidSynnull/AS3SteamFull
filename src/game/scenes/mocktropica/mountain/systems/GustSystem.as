package game.scenes.mocktropica.mountain.systems
{
	import flash.display.MovieClip;
	
	import game.scenes.myth.mountOlympus3.components.Gust;
	import game.scenes.myth.mountOlympus3.nodes.GustNode;
	import game.systems.GameSystem;
	
	public class GustSystem extends GameSystem
	{
		public function GustSystem()
		{
			super( GustNode, updateNode );
		}
		
		private function updateNode( node:GustNode, time:Number ):void {
			var gust:Gust = node.gust;
			gust.stx += gust.vx;			
			if (gust.t-- <= 0) {
				if (gust.whirls.length == 0) {
					gust.active = false;
					return;
				}
			} else if (gust.t % 6 == 0 && gust.whirls.length < 8) {
				makeWhirl(node);
			}			
			var w:Object;
			for(var i:Number = gust.whirls.length-1; i >= 0; i--) {				
				w = gust.whirls[i];				
				w.alph -= 2;
				if (w.alph < 20) {
					//delete w;
					gust.whirls.splice(i,1);
				}				
				if (w.mode == Gust.SINE) {					
					if (w.t < w.maxT) {
						doSine(node, w);
					} else {						
						if (Math.random() < 0.5) {
							w.mode = Gust.SPIRAL;
							var dy:Number = Math.cos(w.t);		// Derivative of sine.
							w.t = Math.atan2(dy, gust.vx);
							if (dy < 0) {
								w.dt = -0.3;
							} else {
								w.dt = 0.3;
							}
						} else {
							w.maxT += Gust.duration;
						}						
					}
					
				} else {
					doSpiral(w);
				}				
			}			
			doDraw(node);			
		}
		
		public function doDraw(node:GustNode):void {
			var gust:Gust = node.gust;
			var clip:MovieClip = node.display.displayObject as MovieClip;
			clip.graphics.clear();			
			var w:Object;
			var pts:Array;
			var pt:Object;
			var prev:Object;			
			for( var i:Number = gust.whirls.length-1; i >= 0; i-- ) {				
				w = gust.whirls[i];
				pts = w.pts;				
				prev = pts[0];
				clip.graphics.lineStyle(1.5, 0xFFFFFF, w.alph);
				clip.graphics.moveTo(prev.x, prev.y);
				for(var j:Number = 1; j < pts.length; j++) {					
					pt = pts[j];
					clip.graphics.curveTo(prev.x, prev.y, (pt.x+prev.x)/2, (pt.y+prev.y)/2);					
					prev = pt;					
				}				
			}			
		}
		
		private function doSine(node:GustNode, w:Object ):void {			
			var gust:Gust = node.gust;
			var clip:MovieClip = node.display.displayObject as MovieClip;
			var pts:Array = w.pts;			
			if (pts.length >= 20) {
				pts.shift();		// Remove oldest point.
			}			
			var prev:Object = pts[pts.length-1];			
			w.t += 0.5;			
			pts.push({x:(prev.x + gust.vx), y:w.y +(w.A * Math.sin(w.t))});			
		}
		
		private function doSpiral( w:Object ):void {			
			var pts:Array = w.pts;			
			if (pts.length >= 60) {
				pts.shift();		// Remove oldest point.
			}			
			var prev:Object = pts[pts.length-1];
			w.t += w.dt;			
			w.A *= 0.96;
			pts.push({ x:(prev.x + w.A*Math.cos(w.t)), y:prev.y +(w.A * Math.sin( w.t )) } );			
		}
		
		public function makeWhirl(node:GustNode):void {			
			var gust:Gust = node.gust;
			var clip:MovieClip = node.display.displayObject as MovieClip;
			var w:Object = new Object();
			w.A = 6 + 2*Math.random();				// Whirl amplitude.			
			w.t = 2*Math.PI*Math.random();				// Whirl timer.
			w.maxT = (1.5 + 2*Math.random())*Math.PI;
			w.alph = 100;
			w.mode = Gust.SINE;
			w.x = gust.stx - 20 + 40*Math.random();
			w.y = -50 + 100*Math.random();
			var pt:Object = {x:w.x + 4, y:w.y + w.A*Math.sin(w.t)};
			w.pts = [pt];
			gust.whirls.push(w);
		} 
	}
}