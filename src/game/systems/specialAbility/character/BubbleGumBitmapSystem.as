package game.systems.specialAbility.character
{
	import flash.display.MovieClip;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.specialAbility.character.BubbleGum;
	import game.creators.entity.EmitterCreator;
	import game.nodes.specialAbility.character.BubbleGumNode;
	import game.systems.SystemPriorities;
	
	import org.flintparticles.twoD.emitters.Emitter2D;
	
	
	
	public class BubbleGumBitmapSystem extends BubbleGumSystem
	{
		private var _nodes:NodeList;
		private var _assetMC:MovieClip;
		
		public function BubbleGumBitmapSystem(assetMC:MovieClip)
		{
			super();
			_assetMC = assetMC;
		}
		override public function addToEngine(systemsManager:Engine):void
		{
			_nodes = systemsManager.getNodeList(BubbleGumNode);
			_nodes.nodeRemoved.add( nodeRemoved );
			super._defaultPriority = SystemPriorities.update;
		}
		
		override public function update( time : Number ) : void
		{
			var node:BubbleGumNode;
			
			for ( node = _nodes.head; node; node = node.next )
			{
				var gum:BubbleGum = node.gum;
				var spatial:Spatial = node.spatial;
				
				if(!gum.popped)
				{
					// Increasing the size of the bubble
					// After max size, make the bubble float up
					if(spatial.scaleX <= gum.maxScale)
					{
						spatial.scaleX += .1;
						spatial.scaleY += .1;
					} else {
						
						if(gum.vy > gum.maxHeight)
						{
							gum.vy += gum.ay;
							gum.vx += gum.ax;
							spatial.y += gum.vy;
							spatial.x += gum.vx;
						} else {
							popBubble(node);
						}
					}
				}
				
			}	
		}
		
		// Remove the bubble and init the particle emitter
		private function popBubble(node:BubbleGumNode):void
		{
			var gum:BubbleGum = node.gum;
			gum.popped = true;
			node.entity.remove(Display);
			
			var spatial:Spatial = node.spatial;
			var particleClass:Class = node.gum.particleClass;
			var emitter:Object = new particleClass();
			emitter.setAssetMC(_assetMC);
			emitter.setBitmap(true);
			emitter.init();
			EmitterCreator.create( group, gum.player.get(Display).container, emitter as Emitter2D, spatial.x, spatial.y );
		}
		public function setAssetMC(assetMC:MovieClip):void
		{
			_assetMC = assetMC;
		}
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(BubbleGumNode);
			_nodes = null;
		}
		
		private function nodeRemoved(node:BubbleGumNode):void
		{
			
		}
		
		
	}
}

