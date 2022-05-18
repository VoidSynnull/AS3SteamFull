package game.data.specialAbility.store
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.particles.emitter.specialAbility.MagicBubbleBlast;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.PerformanceUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class MagicHat extends SpecialAbility
	{
		public function MagicHat()
		{
			super();
		}
		
		override public function destroy():void
		{
			if(_bubbleEmitter)
			{
				_bubbleEmitter = null;
			}
			
			if(_bitmapData)
			{
				_bitmapData.dispose();
				_bitmapData = null;
			}
			
			super.destroy();
		}
		
		override public function init(node:SpecialAbilityNode):void
		{
			super.init(node);
			this.suppressed = true;
			
			// load in swf
			shellApi.loadFile(_particleSwf, swfLoaded);
			_partEntity = CharUtils.getPart(node.entity, _partType);
			
			var entityClip:MovieClip = _partEntity.get(Display).displayObject;
			if(entityClip)
			{
				var active:MovieClip = entityClip.getChildByName("active_obj") as MovieClip;
				if(active)
				{
					_activeEntity = EntityUtils.createSpatialEntity(this, active);
					_activeEntity = TimelineUtils.convertClip(active, _partEntity.group, _activeEntity, _partEntity, false);
					_activeEntity.get(Timeline).gotoAndStop("empty");
				}
			}
		}
		
		private function swfLoaded(mc:MovieClip):void
		{
			if(mc)
			{
				_bitmapData = BitmapUtils.createBitmapData(mc, PerformanceUtils.defaultBitmapQuality);
			}
			
			this.suppressed = false;
		}
		
		override public function activate(node:SpecialAbilityNode):void
		{
 			if(!this.data.isActive)
			{
				if(_bitmapData)
				{
					this.data.isActive = true;
					_bubbleEmitter = new MagicBubbleBlast();
					_bubbleEmitter.init(_bitmapData, 20, null, 20);
					EmitterCreator.create(_partEntity.group, _partEntity.get(Display).displayObject, _bubbleEmitter, 0, 0, _partEntity, "magicBubble");
					
					if(_activeEntity)
					{
						_activeEntity.get(Timeline).gotoAndStop(GeomUtils.randomInt(1,2));
						var spatial:Spatial = _activeEntity.get(Spatial);
						spatial.scaleX = spatial.scaleY = 0;
						
						var display:Display = _activeEntity.get(Display);
						display.alpha = 0;
						
						TweenUtils.globalTo(_activeEntity.group, spatial, 1, {scaleX:1, scaleY:1}, "", .5);
						TweenUtils.globalTo(_activeEntity.group, display, 1, {alpha:1, onComplete:abilityDone}, "", .5);
						
						if(display.displayObject is MovieClip)
						{
							var ear1Clip:DisplayObject = MovieClip(display.displayObject).getChildByName("ear1");
							if(ear1Clip)
							{
								
							}
							
							var ear2Clip:DisplayObject = MovieClip(display.displayObject).getChildByName("ear2");
							if(ear2Clip)
							{
								
							}
						}
					}
				}
			}
		}
		
		private function abilityDone(...args):void
		{
			this.data.isActive = false;
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			//_ear
		}
		
		public var _particleSwf:String = "assets/particles/magicBubble.swf";
		public var _partType:String = CharUtils.HAIR;
		
		private var _partEntity:Entity;
		private var _activeEntity:Entity;
		private var _bubbleEmitter:MagicBubbleBlast;
		private var _bitmapData:BitmapData;
		private var _insideHat:Entity;
		
		private var _ear1:Entity;
		private var _ear2:Entity;
	}
}