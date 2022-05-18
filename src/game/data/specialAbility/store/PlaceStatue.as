// Used by:
// Card 3276 using items storeplantastatue1, storeplantastatue2, storeplantastatue3

package game.data.specialAbility.store
{
	import com.greensock.easing.Quad;
	
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Place;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.CharUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	/**
	 * Place statue on ground and statue scales up with bird animation
	 * 
	 * Required params:
	 * swfPath		String		Path to statue swf
	 * 
	 * Optional params:
	 * extraPath	String		Path to bird swf
	 * x			Number		X location of placement (default is 0)
	 * y			Number		Y location of placement (default is 0)
	 */
	public class PlaceStatue extends SpecialAbility
	{
		override public function activate(node:SpecialAbilityNode):void
		{
			if(!super.data.isActive)
			{
				_finalBirdLoc = new Point(_x, _y);
				super.loadAsset(_swfPath, loadComplete);
				super.loadAsset(_extraPath, extraLoaded);
			}
		}
		
		private function loadComplete(clip:MovieClip):void
		{
			CharUtils.setAnim(super.entity, Place);
			CharUtils.getTimeline(super.entity).handleLabel(Animation.LABEL_TRIGGER, Command.create(onPlace, clip));
			super.setActive(true);
		}
		
		private function onPlace(clip:MovieClip):void
		{
			clip.scaleX = clip.scaleY = 0;
			_statueEntity = new Entity();
			_statueEntity.add(new Display(clip, super.entity.get(Display).container));
			
			var footSpatial:Spatial = CharUtils.getJoint(super.entity, CharUtils.FOOT_BACK).get(Spatial);
			var charSpatial:Spatial = super.entity.get(Spatial);
			
			var spatial:Spatial = new Spatial(charSpatial.x - (footSpatial.x * charSpatial.scale), charSpatial.y + (footSpatial.y * charSpatial.scale));
			_statueEntity.add(spatial);
			
			super.group.addEntity(_statueEntity);
			TweenUtils.globalTo(super.group, spatial, 1, {scaleX:1, scaleY:1, onComplete:statueVisible}, "statueScale");
		}
		
		private function statueVisible():void
		{
			super.setActive(false);
			
			var statueSpatial:Spatial = _statueEntity.get(Spatial);
			
			var bird:Entity = new Entity();
			
			bird.add(new Display(_extraClip, super.entity.get(Display).container));
			group.addEntity(bird);
			
			TimelineUtils.convertClip(_extraClip, group, bird);
			
			var xPos:Number = statueSpatial.x + group.shellApi.offsetX(statueSpatial.x);
			// Randomly choose a side of the screen
			if(Math.ceil(Math.random() * 2) % 2 == 1)
			{
				// flip the bird if randomly chosen left side of screen
				xPos = statueSpatial.x - group.shellApi.offsetX(statueSpatial.x);
				_extraClip.scaleX = -1;
			}
			
			var spatial:Spatial = new Spatial(xPos, statueSpatial.y - group.shellApi.viewportHeight/2);
			bird.add(spatial);
			
			var finalX:Number = statueSpatial.x + _finalBirdLoc.x;
			var finalY:Number = statueSpatial.y + _finalBirdLoc.y;
			
			TweenUtils.globalTo(group, spatial, 1.5, {x:finalX, y:finalY, ease:Quad.easeOut, onComplete:birdFinish, onCompleteParams:[bird]});
		}
		
		private function birdFinish(entity:Entity):void
		{
			entity.get(Timeline).gotoAndStop("end");
		}
		
		private function extraLoaded(clip:MovieClip):void
		{
			_extraClip = clip;
		}
		
		public var required:Array = ["swfPath"];
		
		public var _swfPath:String;
		public var _extraPath:String;
		public var _x:Number = 0;
		public var _y:Number = 0;
		
		private var _extraClip:MovieClip;
		private var _statueEntity:Entity;
		private var _birdSpeed:Number = 200;
		private var _finalBirdLoc:Point = new Point(0,0);
	}
}