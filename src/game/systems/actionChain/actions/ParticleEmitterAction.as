package game.systems.actionChain.actions
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.creators.entity.EmitterCreator;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.actionChain.ActionCommand;
	import game.util.ClassUtils;
	
	// Add particle emitter to entity
	// Use PartParticleAction if you want to attach particles to an avatar part
	public class ParticleEmitterAction extends ActionCommand
	{
		private var emitter:Class;
		private var container:DisplayObjectContainer;
		private var parent:Entity;
		private var follow:Spatial;
		private var args:Array;
		
		private var _id:String;
		
		/**
		 * 
		 * @param emitter - the class that will be used to create the emitter
		 * @param display - the container to add the emitter too
		 * @param parent - the parent if there is one
		 * @param follow - the entity the emitter to follow
		 * @param args - the args that the init function of the emitter needs
		 */		
		public function ParticleEmitterAction(emitter:Class, container:DisplayObjectContainer, parent:Entity = null, follow:Entity = null, args:Array = null)
		{
			_id = ClassUtils.getNameByObject(emitter);
			_id = _id.substr(_id.indexOf("::") + 2);

			this.emitter = emitter;
			this.container = container;
			this.parent = parent;
			this.follow = follow.get(Spatial);
			this.args = args;
		}
		
		override public function preExecute(_pcallback:Function, group:Group, node:SpecialAbilityNode = null ):void
		{
			var emitterObj:* = new emitter();

			if(args)
			{
				emitterObj.init.apply(null, this.args);
				/*
				switch(_args.length)
				{
					case 0:
						emitterObj.init();
						break;
					case 1:
						emitterObj.init(_args[0]);
						break;
					case 2:
						emitterObj.init(_args[0], _args[1]);
						break;
					case 3:
						emitterObj.init(_args[0], _args[1], _args[2]);
						break;
					case 4:
						emitterObj.init(_args[0], _args[1], _args[2], _args[3]);
						break;
					case 5:
						emitterObj.init(_args[0], _args[1], _args[2], _args[3], _args[4]);
						break;
					case 6:
						emitterObj.init(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5]);
						break;
					case 7:
						emitterObj.init(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6]);
						break;
					case 8:
						emitterObj.init(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7]);
						break;
					case 9:
						emitterObj.init(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7], _args[8]);
						break;
				}
				*/
			}
			else
			{
				emitterObj.init();
			}

			EmitterCreator.create(group, container, emitterObj, 0, 0, parent, _id, follow, true);
		}
		
		override public function revert( group:Group ):void
		{
			// remove particles
			var emitterEntity:Entity = group.getEntityById(_id);
			if (emitterEntity)
				group.removeEntity(emitterEntity);
		}
	}
}