package game.systems.actionChain.actions
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.creators.entity.EmitterCreator;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.particles.emitter.specialAbility.VortexSwirlParticles;
	import game.systems.actionChain.ActionCommand;
	
	public class CreateVortexAction extends ActionCommand
	{
		private var url:String;
		private var position:Entity;
		private var offsetY:Number;
		private var epsilon:Number;
		private var emitterEntity:Entity;
		private var callback:Function;
		
		public function CreateVortexAction(swf:String, position:Entity, offsetY:Number = -80, epsilon:Number = 50)
		{
			url = swf;
			this.position = position;
			this.offsetY = offsetY;
			this.epsilon = epsilon;
		}
		
		override public function preExecute(_pcallback:Function, group:Group, node:SpecialAbilityNode = null ):void
		{
			callback = _pcallback;
			group.shellApi.loadFile(group.shellApi.assetPrefix+url, assetLoaded);
		}
		
		private function assetLoaded(asset:MovieClip):void
		{
			var container:DisplayObjectContainer = position.get(Display).container;
			var emitterObj:VortexSwirlParticles = new VortexSwirlParticles();
			var spatial:Spatial = position.get(Spatial);
			emitterObj.init(asset, spatial,offsetY, epsilon);
			emitterEntity = EmitterCreator.create(position.group, container, emitterObj, 0, 0, null, "vortex",null, true);
			var emitterSpatial:Spatial = emitterEntity.get(Spatial);
			emitterSpatial.x = spatial.x;
			emitterSpatial.y = spatial.y + offsetY;
			if(!noWait)
			{
				if(callback)
					callback(this);
				callback = null;
			}
		}
		
		override public function revert( group:Group ):void
		{
			if (emitterEntity)
				group.removeEntity(emitterEntity);
			emitterEntity = null;
		}
	}
}