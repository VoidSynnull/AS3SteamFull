package game.scenes.poptropolis.archery.systems 
{
	import flash.display.MovieClip;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	import game.scenes.poptropolis.archery.components.Flag;
	import game.scenes.poptropolis.archery.nodes.ArrowNode;
	import game.scenes.poptropolis.archery.nodes.FlagNode;
	import game.scenes.poptropolis.archery.nodes.TreeNode;
	import game.scenes.poptropolis.archery.nodes.WindNode;
	import game.systems.SystemPriorities;
	
	public class ArcherySystem extends System
	{
		private var _arrows:NodeList;
		private var _flags:NodeList;
		private var _winds:NodeList;
		private var _trees:NodeList;
		private var easing:Number = 0.15;
		
		public function ArcherySystem()
		{
			super._defaultPriority = SystemPriorities.update;
		}
		
		override public function addToEngine( systemsManager:Engine ):void
		{
			_arrows = systemManager.getNodeList( ArrowNode );
			_flags = systemManager.getNodeList( FlagNode );
			_winds = systemManager.getNodeList( WindNode );
			_trees = systemManager.getNodeList( TreeNode );
		}
		
		override public function update( time:Number ):void
		{
			var arrow:ArrowNode;
			var flag:FlagNode;
			var wind:WindNode;
			var tree:TreeNode;
			
			for(arrow = _arrows.head; arrow; arrow = arrow.next)
			{
				//trace("MOUSE" + arrow.arrow.mouse.x);
				
				var spatial:Spatial = arrow.spatial;
				var xPos:Number = spatial.x;
				var yPos:Number = spatial.y;
				
				if(arrow.arrow.firing){
					if(spatial.scaleY > arrow.arrow.finalScale){
						xPos += (arrow.arrow.targetX - spatial.x) * easing;
						yPos += (arrow.arrow.targetY - spatial.y) * easing;
						
						spatial.x = xPos;
						spatial.y = yPos - 100*Math.sin( Math.PI*(1 - ((arrow.arrow.finalScale - spatial.scaleY)*10)/(arrow.arrow.finalScale- 100)) );
						spatial.scaleY += (arrow.arrow.finalScale - .05 - spatial.scaleY) * easing*0.5;
						spatial.scaleX += (arrow.arrow.finalScale*0.2 - spatial.scaleX) * easing*0.5;
						spatial.rotation += -3;
					}else{
						arrow.arrow.firing = false;
						arrow.arrow.fired = true;
						if(arrow.arrow.finalScale == 0){
							arrow.display.visible = false;
						}
						
						//if(MovieClip(arrow.display.displayObject["arrow"]).currentFrame < 10){
						//	MovieClip(arrow.display.displayObject["arrow"]).nextFrame();
						//}
						arrow.arrow.arrowReady.dispatch();
					}
					
				}else if(!arrow.arrow.fired){
					
					var dx:Number = arrow.arrow.mouse.x + arrow.arrow.viewPort.x - spatial.x;
					var dy:Number = arrow.arrow.mouse.y + arrow.arrow.viewPort.y - spatial.y;
					spatial.rotation = (Math.atan2(dy, dx) * 180 / Math.PI) + 20;
				}else{
					var a:MovieClip = arrow.display.displayObject["arrow"] as MovieClip;
					if(a.currentFrame < 11){
						a.nextFrame();
					}
				}
			}
			
			for(flag = _flags.head; flag; flag = flag.next)
			{
				updateFlag(flag.flag);
				
				var d:MovieClip = flag.display.displayObject as MovieClip;
				d.graphics.clear();
				d.graphics.lineStyle(1.5, 0x833F27);
				d.graphics.beginFill(0xB94F43);
				d.graphics.moveTo(flag.flag.p0.x, flag.flag.p0.y);
				d.graphics.curveTo(flag.flag.p1.x, flag.flag.p1.y, flag.flag.p2.x, flag.flag.p2.y);
				d.graphics.curveTo(flag.flag.p3.x, flag.flag.p3.y, flag.flag.p5.x, flag.flag.p5.y);
				d.graphics.curveTo(flag.flag.p4.x, flag.flag.p4.y, flag.flag.p0.x, flag.flag.p0.y);	
				
				if (Math.random()*30 < 1) {
					flag.flag.speed = Math.random()*0.05 + 0.05;
				}
			}
			
			tree = _trees.head;
			wind = _winds.head;
			if(tree)
			{
				var t:MovieClip = tree.display.displayObject as MovieClip;
				var ts:Spatial = tree.spatial;
				
				var tdx:Number = tree.tree.targetRot - ts.rotation;
				var ax:Number = tdx * tree.tree.spring;
				tree.tree.vx += ax;
				tree.tree.vx *= tree.tree.friction;
				ts.rotation += tree.tree.vx;
				
				t.leaf1.rotation += tree.tree.vx*-3;
				t.leaf2.rotation += tree.tree.vx*-1.5;
				t.leaf3.rotation += tree.tree.vx;
				t.leaf4.rotation += tree.tree.vx;
				t.leaf5.rotation += tree.tree.vx*3;
				t.leaf6.rotation += tree.tree.vx*-3;
				t.leaf7.rotation += tree.tree.vx*-6;
				tree.tree.targetRot = randRange(-wind.wind.windSpeed/15, wind.wind.windSpeed/15);
			}
			
			flag = _flags.head;
			for(wind = _winds.head; wind; wind = wind.next)
			{
				var variance:Number = randRange(-1, 1);
				wind.wind.windSpeed += variance / 2;
				if(wind.wind.windSpeed > 50){
					wind.wind.windSpeed = 50;
				}
				if(wind.wind.windSpeed < -50){
					wind.wind.windSpeed = -50;
				}
				var w:MovieClip = wind.display.displayObject as MovieClip;
				w.windSpeed.text = Math.abs(Math.ceil(wind.wind.windSpeed/5));
				
				if(flag)
				{
					var fs:Spatial = flag.spatial;
					if(wind.wind.windSpeed < 0){
						w.flag.gotoAndStop(2);
						fs.scaleX = -1;
						fs.x = 592;
						flag.flag.leftOffset = 20;
					}else{
						w.flag.gotoAndStop(1);
						fs.scaleX = 1;
						fs.x = 590;
						flag.flag.leftOffset = 0;
					}
				}
				else
				{
					if(wind.wind.windSpeed < 0){
						w.flag.gotoAndStop(2);
					}else{
						w.flag.gotoAndStop(1);
					}
				}
			}
		}
		
		private function updateFlag(flag:Flag):void
		{
			flag.p1t += flag.speed;
			flag.p2t += flag.speed;
			flag.p3t += flag.speed;
			flag.p4t += flag.speed;
			flag.p1.y = flag.p1StartY + flag.leftOffset + 20*Math.sin(flag.p1t);
			flag.p2.y = flag.p2StartY + flag.leftOffset + 20*Math.sin(flag.p2t);
			flag.p3.y = flag.p3StartY + flag.leftOffset + 20*Math.sin(flag.p3t);
			flag.p4.y = flag.p4StartY + flag.leftOffset + 20*Math.sin(flag.p4t);			
			///////////////STILL NEED TO ACCOUNT FOR WHATEVER 'LEFTOFFSET' IS/
		}
		
		override public function removeFromEngine( systemsManager:Engine ):void
		{
			systemsManager.releaseNodeList( ArrowNode );
			_arrows = null;
		}
		
		private function randRange(min:Number, max:Number):Number {
			var randomNum:Number = Math.floor(Math.random()*(max-min+1))+min;
				return randomNum;
		}
	}
}