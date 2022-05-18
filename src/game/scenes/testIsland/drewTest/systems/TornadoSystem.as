package game.scenes.testIsland.drewTest.systems
{
	import flash.display.DisplayObjectContainer;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import game.scenes.testIsland.drewTest.classes.TornadoParticle;
	import game.scenes.testIsland.drewTest.nodes.TornadoNode;
	import game.systems.GameSystem;
	import game.util.Utils;
	
	import org.flintparticles.common.displayObjects.Blob;
	
	public class TornadoSystem extends GameSystem
	{
		public const VELOCITY_FACTOR:Number = 0.002;
		
		public function TornadoSystem()
		{
			super(TornadoNode, updateNode);
		}
		
		public function updateNode(node:TornadoNode, time:Number):void
		{
			this.updateTime(node, time);
			
			var velocityX:Number = -node.motion.velocity.x * this.VELOCITY_FACTOR;
			
			this.updateCircles(node, time, velocityX);
			this.updateParticles(node, time, velocityX);
			
			//this.draw(node);
		}
		
		/**
		 * Keep this. This might come in handy.
		 */
		private function draw(node:TornadoNode):void
		{
			var graphics:Graphics = Sprite(node.display.displayObject).graphics;
			
			var top:Shape = node.tornado.circles.last;
			var bottom:Shape = node.tornado.circles.first;
			
			graphics.clear();
			graphics.beginFill(0xFF0000, 0.5);
			graphics.moveTo(top.x - top.width/2, top.y);
			graphics.curveTo(bottom.x - bottom.width/2, top.y/2, bottom.x - bottom.width/2, 0);
			graphics.lineTo(bottom.x + bottom.width/2, 0);
			graphics.curveTo(bottom.x + bottom.width/2, top.y/2, top.x + top.width/2, top.y);
			graphics.lineTo(top.x - top.width/2, top.y);
			graphics.endFill();
		}
		
		private function updateTime(node:TornadoNode, time:Number):void
		{
			node.tornado.time += node.tornado.speed * time;
			
			while(node.tornado.time >= Math.PI * 2)
				node.tornado.time -= Math.PI * 2;
		}
		
		/**
		 * Circle Updates
		 */
		
		private function updateCircles(node:TornadoNode, time:Number, velocityX:Number):void
		{
			this.resetCircles(node);
			
			for(var i:uint = 0; i < node.tornado.circles.size; i++)
			{
				var circle:Shape = node.tornado.circles.itemAt(i);
				
				this.updateCircleX(circle, node, velocityX);
			}
		}
		
		private function updateCircleX(circle:Shape, node, velocityX:Number):void
		{
			var magnitude:Number = -circle.y * node.tornado.magnitude;
			var radians:Number = Math.cos(node.tornado.time - node.tornado.delay * -circle.y);
			
			circle.x = magnitude * radians;
			circle.x += velocityX * -circle.y;
		}
		
		private function resetCircles(node:TornadoNode):void
		{
			if(!node.tornado.resetCircles) return;
			
			var circle:Shape;
			if(node.tornado.circles.size > node.tornado.numCircles)
			{
				while(node.tornado.circles.size > node.tornado.numCircles)
				{
					circle = node.tornado.circles.itemAt(node.tornado.numCircles);
					node.display.displayObject.removeChild(circle);
					node.tornado.circles.removeAt(node.tornado.numCircles);
				}
			}
			else if(node.tornado.circles.size < node.tornado.numCircles)
			{
				var lastIndex:uint = 0;
				if(node.tornado.circles.size > 0)
					lastIndex = node.display.displayObject.getChildIndex(node.tornado.circles.last) + 1;
				
				while(node.tornado.circles.size < node.tornado.numCircles)
				{
					circle = new Shape();
					node.display.displayObject.addChildAt(circle, lastIndex++);
					node.tornado.circles.addLast(circle);
				}
			}
			
			var radius:Number = node.tornado.startRadius;
			for(var i:uint = 0; i < node.tornado.circles.size; i++)
			{
				circle = node.tornado.circles.itemAt(i);
				circle.x = 0;
				
				/**
				 * The (node.tornado.startRadius * 0.5) is to offset circles for the the fact that particles are
				 * spawning at (0, 0), but the circles are being drawn there too, and their radii are lower than
				 * (0, 0). So all circles are being moved up by the start radius to compensate.
				 */
				circle.y = i * -node.tornado.circleOffsetY - (node.tornado.startRadius * 0.5);
				
				var box:Rectangle = new Rectangle(-radius, -radius, radius * 2, radius * 2);
				
				var matrix:Matrix = new Matrix();
				matrix.createGradientBox(box.width, box.height, 0, box.left, box.top);
				
				circle.graphics.clear();
				circle.graphics.beginGradientFill(GradientType.RADIAL, [node.tornado.circleColor, 0x111111], [1, 0], [100, 255], matrix);
				circle.graphics.drawCircle(0, 0, box.width * 0.5);
				circle.graphics.endFill();
				
				radius += node.tornado.circleOffsetX;
			}
			
			node.tornado.resetCircles = false;
		}
		
		/**
		 * Particle Updates
		 */
		
		private function updateParticles(node:TornadoNode, time:Number, velocityX:Number):void
		{
			this.resetParticles(node);
			this.updateParticleCount(node);
			
			var height:Number = node.tornado.height;
			
			for(var i:uint = 0; i < node.tornado.particles.size; i++)
			{
				var particle:TornadoParticle = node.tornado.particles.itemAt(i);
				
				this.updateParticleTime(particle, time, node);
				this.updateParticleY(particle, time, node, height);
				this.updateParticleX(particle, node, velocityX);
				this.updateParticleRotation(particle, time);
				this.updateParticleLayer(particle, node);
			}
		}
		
		private function updateParticleTime(particle:TornadoParticle, time:Number, node:TornadoNode):void
		{
			particle.time += (node.tornado.speed + particle.velocityX) * time;
			
			while(particle.time >= Math.PI * 2)
				particle.time -= Math.PI * 2;
		}
		
		private function updateParticleY(particle:TornadoParticle, time:Number, node:TornadoNode, height:Number):void
		{
			particle.shape.y += particle.velocityY * node.tornado.speed * time;
			
			if(particle.shape.y < -height)
				node.tornado.dead.push(particle);
		}
		
		private function updateParticleX(particle:TornadoParticle, node:TornadoNode, velocityX:Number):void
		{
			//For testing...
			//this.shape.y = -node.tornado.height;
			
			//Get where the particle should be positioned in the Tornado's "center" line.
			var magnitude:Number = -particle.shape.y * node.tornado.magnitude;
			var radians:Number = Math.cos(node.tornado.time - node.tornado.delay * -particle.shape.y);
			var circleRatio:Number = (node.tornado.circleOffsetX * 2 / node.tornado.circleOffsetY);
			
			/**
			 * Position it where it should be in the tornado "center" line.
			 * Add an offset for the radius of the funnel since particles need to go around it.
			 * Add an offset for an optionally set offset distance particles should spin away from the funnel.
			 * Add an offset for velocity.
			 */
			particle.shape.x = magnitude * radians;
			particle.shape.x += Math.cos(particle.time) * (node.tornado.startRadius + magnitude * circleRatio);
			particle.shape.x += Math.cos(particle.time) * node.tornado.particleOffsetX;
			particle.shape.x += velocityX * -particle.shape.y;
		}
		
		private function updateParticleRotation(particle:TornadoParticle, time:Number):void
		{
			particle.shape.rotation += particle.rotation * time;
		}
		
		private function updateParticleLayer(particle:TornadoParticle, node:TornadoNode):void
		{
			//This determines when the particle should be moved to the front or back visually.
			if(particle.isForward && Math.sin(particle.time) < 0 || !particle.isForward && Math.sin(particle.time) > 0)
				this.swapLayer(particle, node.display.displayObject);
		}
		
		private function updateParticleCount(node:TornadoNode):void
		{
			var container:DisplayObjectContainer = node.display.displayObject;
			
			while(node.tornado.dead.length > 0)
			{
				var particle:TornadoParticle = node.tornado.dead.pop();
				
				if(node.tornado.particles.size > node.tornado.numParticles)
				{
					node.tornado.particles.remove(particle);
					container.removeChild(particle.shape);
				}
				else this.createParticle(node, particle);
			}
			
			while(node.tornado.particles.size < node.tornado.numParticles)
				this.createParticle(node, null);
		}
		
		private function resetParticles(node:TornadoNode):void
		{
			if(!node.tornado.resetParticles) return;
			
			while(node.tornado.particles.size > 0)
			{
				node.display.displayObject.removeChild(node.tornado.particles.first);
				node.tornado.particles.removeAt(0);
			}
			
			while(node.tornado.particles.size < node.tornado.numParticles)
				this.createParticle(node, null);
			
			node.tornado.resetParticles = false;
		}
		
		private function createParticle(node:TornadoNode, particle:TornadoParticle):void
		{
			var container:DisplayObjectContainer = node.display.displayObject;
			var color:uint = node.tornado.particleColors[Utils.randInRange(0, node.tornado.particleColors.length - 1)];
			
			if(particle)
			{
				Blob(particle.shape).color = color;
				particle.shape.x = 0;
			}
			else
			{
				var shape:Blob = new Blob(8, color);
				particle = new TornadoParticle(shape);
				container.addChild(particle.shape);
				node.tornado.particles.add(particle);
			}
			
			/**
			 * All particles are being placed at the bottom of the first circle visually, but technically
			 * that's not where (0, 0) is. This is done so it looks accurate, but depending on the start
			 * radius, you should position your tornado a start radius above the ground.
			 */
			if(!node.tornado.resetParticles) particle.shape.y = 0;
			else particle.shape.y = Utils.randNumInRange(-node.tornado.height, 0);
			
			this.swapLayer(particle, container);
		}
		
		private function swapLayer(particle:TornadoParticle, container:DisplayObjectContainer):void
		{
			if(particle.isForward)
			{
				particle.isForward = false;
				container.setChildIndex(particle.shape, 0);
			}
			else
			{
				particle.isForward = true;
				container.setChildIndex(particle.shape, container.numChildren - 1);
			}
		}
	}
}