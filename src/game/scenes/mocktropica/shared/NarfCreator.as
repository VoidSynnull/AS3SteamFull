package game.scenes.mocktropica.shared
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.motion.MotionTarget;
	import game.components.entity.Sleep;
	import game.creators.entity.BitmapTimelineCreator;
	import game.scene.template.CharacterGroup;
	import game.scenes.mocktropica.shared.components.Narf;
	import game.scenes.mocktropica.shared.petStates.PetEatState;
	import game.scenes.mocktropica.shared.petStates.PetJumpState;
	import game.scenes.mocktropica.shared.petStates.PetLandState;
	import game.scenes.mocktropica.shared.petStates.PetRunState;
	import game.scenes.mocktropica.shared.petStates.PetStandState;
	import game.scenes.mocktropica.shared.petStates.PetWalkState;
	import game.systems.entity.character.clipChar.MovieclipState;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;

	public class NarfCreator
	{
		public function NarfCreator(sceneGroup:Group, charGroup:CharacterGroup, container:DisplayObjectContainer):void
		{
			_sceneGroup = sceneGroup;
			_charGroup = charGroup;
			_container = container;
		}
		
		public function create(follow:Entity, handler:Function = null):void
		{
			_sceneGroup.shellApi.loadFile(_sceneGroup.shellApi.assetPrefix + "scenes/" + _sceneGroup.shellApi.island + "/shared/narf.swf", Command.create(onLoaded, follow, handler));
		}
		
		private function onLoaded( clip:MovieClip, follow:Entity, handler:Function):void
		{
			var entity:Entity = new Entity();
			_sceneGroup.addEntity(entity);
			entity = EntityUtils.createSpatialEntity(_sceneGroup, clip, _container);
			
			TimelineUtils.convertClip(clip, _sceneGroup, entity);
			entity.add(new Sleep(false, true));
			
			var followSpatial:Spatial = follow.get(Spatial);
			var entitySpatial:Spatial = entity.get(Spatial);
			
			entitySpatial.scale = Math.random() * .5 + .75;
			
			var narf:Narf = new Narf();
			narf.walkSpeed = Math.random() * 250 + 100;
			narf.runSpeed = Math.random() * 500 + 1000;
			narf.jumpHeight = -2500;
			
			narf.randDist = Math.random() * 200 - 100;
			entity.add(narf);
			
			entitySpatial.x = followSpatial.x + narf.randDist;
			entitySpatial.y = (followSpatial.y + followSpatial.height/2) - entitySpatial.height;
			
			var motion:Motion = new Motion();
			motion.maxVelocity = new Point(400, 400);
			entity.add(motion);
			
			var target:MotionTarget = new MotionTarget();
			target.targetSpatial = follow.get(Spatial);
			target.useSpatial = true;
			entity.add(target);
			
			_charGroup.addTimelineFSM(entity, true, new <Class>[PetStandState, PetWalkState, PetRunState, PetJumpState, PetLandState, PetEatState], MovieclipState.STAND);
			
			if(handler != null)
				handler(entity);
		}

		private var _container:DisplayObjectContainer;
		private var _sceneGroup:Group;
		private var _charGroup:CharacterGroup
	}
}