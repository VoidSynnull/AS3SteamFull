package game.scenes.arab1.shared.creators
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Scene;
	import engine.util.Command;
	
	import game.components.entity.FollowClipInTimeline;
	import game.components.entity.Sleep;
	import game.components.entity.character.Character;
	import game.components.motion.Edge;
	import game.components.motion.MotionTarget;
	import game.components.motion.TargetSpatial;
	import game.components.render.DynamicWire;
	import game.creators.ui.ToolTipCreator;
	import game.scene.template.CharacterGroup;
	import game.scenes.arab1.shared.camelStates.CamelPulledState;
	import game.scenes.arab1.shared.camelStates.CamelStandState;
	import game.scenes.arab1.shared.camelStates.CamelWalkState;
	import game.scenes.arab1.shared.components.Camel;
	import game.systems.SystemPriorities;
	import game.systems.entity.FollowClipInTimelineSystem;
	import game.systems.entity.character.clipChar.MovieclipState;
	import game.systems.render.DynamicWireSystem;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;

	public class CamelCreator
	{
		private var _scene:Scene;
		private var _charGroup:CharacterGroup;
		private var _container:DisplayObjectContainer;
		private var _camels:uint;
		
		public var camelCreated:Signal;
		
		public function CamelCreator(scene:Scene, container:DisplayObjectContainer)
		{
			_scene = scene;
			_charGroup = new CharacterGroup();
			_charGroup.setupGroup(_scene, container);
			_container = container;
			_camels = 0;
			camelCreated = new Signal(Entity);
		}
		
		public function create(position:Point = null, handler:Entity = null, ropeLength:Number = 300, created:Function = null):void
		{
			if(created != null)
				camelCreated.add(created);
			_scene.shellApi.loadFile(_scene.shellApi.assetPrefix + "scenes/" + _scene.shellApi.island + "/shared/camel.swf", Command.create(onLoaded, handler, position, ropeLength));
		}
		
		private function onLoaded(asset:*, handler:Entity, position:Point, ropeLength:Number):void
		{
			if(_camels == 0)
			{
				_scene.addSystem(new DynamicWireSystem());
				_scene.addSystem(new FollowClipInTimelineSystem(), SystemPriorities.preRender);
			}
			
			++_camels;
			
			var clip:MovieClip = asset["avatar"];
			
			if(PlatformUtils.isMobileOS)
				BitmapUtils.convertContainer(clip);
			
			if(position == null)
			{
				if(handler != null)
				{
					var handlerSpatial:Spatial = handler.get(Spatial);
					position = new Point(handlerSpatial.x + (ropeLength / 2) * (handlerSpatial.scaleX / Math.abs(handlerSpatial.scaleX)), handlerSpatial.y - handlerSpatial.height);
				}
				else
					position = new Point();
			}
			
			clip.x = position.x;
			clip.y = position.y;
			
			clip.mouseEnabled = clip.mouseChildren = false;
			var entity:Entity = TimelineUtils.convertAllClips(clip, null, _scene);
			entity.add(new Spatial(clip.x, clip.y)).add(new Display(clip, _container)).add(new Motion());
			var edge:Edge = new Edge();
			edge.unscaled = clip.getRect(clip);
			edge.unscaled.bottom *= .9;
			
			var leadDistance:Number = ropeLength + edge.unscaled.right * .66;
			
			var camel:Camel = new Camel(leadDistance);
			
			camel.harnes = EntityUtils.createSpatialEntity(_scene, new MovieClip(), _container);
			camel.harnes.add(new FollowClipInTimeline(clip.Head, new Point(30, 25), entity.get(Spatial)));
			
			camel.lead = EntityUtils.createSpatialEntity(_scene, new MovieClip(), _container);
			camel.lead.add(new FollowClipInTimeline(clip.Head, REIGNS, entity.get(Spatial)));
			
			camel.leash = EntityUtils.createSpatialEntity(_scene, new MovieClip(), _container);
			camel.harnes.add(new TargetSpatial(camel.lead.get(Spatial)));
			camel.harnes.add(new DynamicWire(ropeLength,0xB84637,0xB84637,3));
			
			entity.add(camel).add(edge).add(new MotionTarget()).add(new Id("camel"+_camels)).remove(Sleep);
			
			InteractionCreator.addToEntity(entity, ["click"]);
			
			setCamelsHandler(entity, handler);
			
			_charGroup.addTimelineFSM(entity, true, new <Class>[CamelStandState, CamelWalkState, CamelPulledState],MovieclipState.STAND);
			
			camelCreated.dispatch(entity);
		}
		
		public function setCamelsHandler(camelEntity:Entity, handler:Entity = null):void
		{
			var camel:Camel = camelEntity.get(Camel);
			
			camel.handler = handler;
			
			var follow:FollowClipInTimeline = camel.lead.get(FollowClipInTimeline);
			
			var target:MotionTarget = camelEntity.get(MotionTarget); 
			
			var clip:MovieClip = EntityUtils.getDisplayObject(camelEntity) as MovieClip;
			
			var camelSpatial:Spatial = camelEntity.get(Spatial);
			
			var spatial:Spatial;
			
			if(handler != null)
			{
				DisplayUtils.moveToOverUnder(clip, EntityUtils.getDisplayObject(handler), false);
				DisplayUtils.moveToOverUnder(EntityUtils.getDisplayObject(camel.leash),EntityUtils.getDisplayObject(handler));
				spatial = handler.get(Spatial);
				target.targetSpatial = spatial;
				
				if(spatial.x < camelSpatial.x)
					camelSpatial.scaleX = -1;
				else
					camelSpatial.scaleX = 1;
				
				if(handler.get(Character))
				{
					if(handler == _scene.shellApi.player)
					{
						_scene.shellApi.completeEvent(PLAYER_HOLDING_CAMEL);
						ToolTipCreator.removeFromEntity(camelEntity);
					}
					else
					{
						_scene.shellApi.removeEvent(PLAYER_HOLDING_CAMEL);
						ToolTipCreator.addToEntity(camelEntity);
					}
					
					Interaction(camelEntity.get(Interaction)).lock = (handler == _scene.shellApi.player);
					
					var handDisplay:DisplayObject = EntityUtils.getDisplayObject(SkinUtils.getSkinPartEntity(handler, CharUtils.HAND_FRONT));
					follow.clip = handDisplay;
					follow.parent = spatial;
				}
				else
				{
					follow.clip = EntityUtils.getDisplayObject(handler);
					follow.parent = null;
				}
				follow.offSet = new Point();
			}
			else
			{
				_scene.shellApi.removeEvent(PLAYER_HOLDING_CAMEL);
				
				DisplayUtils.moveToBack(clip);
				
				spatial = camelEntity.get(Spatial);
				target.targetX = spatial.x;
				target.targetY = spatial.y;
				
				follow.clip = clip.Head;
				follow.offSet = REIGNS;
				follow.parent = spatial;
			}
		}
		
		public static const PLAYER_HOLDING_CAMEL:String = "player_holding_camel";
		
		public static const REIGNS:Point = new Point(5, 15);
	}
}