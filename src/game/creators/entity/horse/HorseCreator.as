package game.creators.entity.horse
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Scene;
	import engine.util.Command;
	
	import game.components.motion.Edge;
	import game.components.motion.MotionTarget;
	import game.creators.entity.horse.states.HorseJumpState;
	import game.creators.entity.horse.states.HorseStandState;
	import game.creators.entity.horse.states.HorseWalkState;
	import game.scene.template.CharacterGroup;
	import game.systems.entity.character.clipChar.MovieclipState;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;

	public class HorseCreator
	{
		private var _scene:Scene;
		private var _charGroup:CharacterGroup;
		private var _container:DisplayObjectContainer;
		
		public function HorseCreator(scene:Scene, container:DisplayObjectContainer)
		{
			_scene = scene;
			_charGroup = scene.getGroupById(CharacterGroup.GROUP_ID) as CharacterGroup;
			if(!_charGroup){
				_charGroup = new CharacterGroup();
			}
			_charGroup.setupGroup(_scene, container);
			_container = container;
		}
		
		public function create(position:Point, rideable:Boolean = false, created:Function = null):void
		{
			_scene.shellApi.loadFile(_scene.shellApi.assetPrefix + "entity/horse/horse.swf", Command.create(onLoaded, position, rideable, created));
		}
		
		private function onLoaded(asset:*, position:Point, rideable:Boolean = false, created:Function = null):void
		{
			var clip:MovieClip = asset["avatar"];
			clip.x = position.x;
			clip.y = position.y;
			
			var entity:Entity = EntityUtils.createMovingEntity(_scene,clip,_container);
			//entity = TimelineUtils.convertClip(clip,_scene,null,null,true,20);
			var spatial:Spatial = entity.get(Spatial);
			var motion:Motion = entity.get(Motion);
			entity = TimelineUtils.convertAllClips(clip,entity,_scene,false);
			// add Spatial & motion
			entity.add(spatial);
			entity.add(motion);

			var edge:Edge = new Edge();
			edge.unscaled = clip.getRect(clip);
			
			var target:MotionTarget = new MotionTarget();
			if(rideable){
				// player can ride
				
			}
			
			SceneUtil.setCameraTarget(_scene,entity);

			entity.add(target).add(edge);
			var states:Vector.<Class> = new Vector.<Class>();
			states.push(HorseStandState, HorseWalkState, HorseJumpState);
			_charGroup.addTimelineFSM(entity, true,states,MovieclipState.STAND);
			
			if(created){
				created(entity);
			}
		}
		
		
		
		
	}
}