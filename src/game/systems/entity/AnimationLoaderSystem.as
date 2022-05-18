package game.systems.entity
{
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.System;
	import ash.tools.ListIteratingSystem;
	
	import engine.ShellApi;
	import engine.managers.GroupManager;
	
	import game.components.entity.Parent;
	import game.components.entity.character.Creature;
	import game.components.entity.character.animation.AnimationSlot;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.entity.character.part.Joint;
	import game.data.animation.Animation;
	import game.data.animation.AnimationLibrary;
	import game.data.animation.entity.PartAnimationData;
	import game.nodes.entity.AnimationLoaderNode;
	import game.systems.SystemPriorities;
	
	import org.as3commons.collections.utils.ArrayUtils;
	
	/**
	 * Applies animations to a rig.
	 * Processes the animation slot entities.
	 * Checks for a next aniamtion, and applies that animation to the rig
	 * Checks for inactive slots &amp; removes them
	 * Checks for relaod, which reapplies the current animations data tot the joints
	 */
	public class AnimationLoaderSystem extends ListIteratingSystem
	{
		public function AnimationLoaderSystem()
		{
			super( AnimationLoaderNode, updateNode );
			super._defaultPriority = SystemPriorities.loadAnim;
		}

		override public function addToEngine( systemManager : Engine ) : void
		{
			_animationLibrary = new AnimationLibrary( _shellApi );
			super.addToEngine( systemManager );
			_newSystems = new Array();
		}
		
		override public function removeFromEngine( systemManager : Engine ) : void
		{
			if( _animationLibrary )
			{
				_animationLibrary.destroy();
				_animationLibrary = null;
			}
			super.removeFromEngine( systemManager );
		}
		
		override public function update( time : Number ) : void
		{
			super.update(time);
			
			// queue new systems required by animation classes
			if (_newSystems.length > 0)
			{
				super.systemManager.updateComplete.addOnce(addNewSystems);
			}
		}
		
		/**
		 * Applies animation data to joints when a new animation has been specifieid.
		 * Checks for next animation, inactive slot, and reload.
		 * 
		 * Next animation - retrieves specified Animation class from Animation Library ( which may have to load the xml )
		 * 1. updates RigAnimation componnet with new animation, 
		 * 2. resets timeline
		 * 3. applies animation data to joints
		 * 4. removes previous animation
		 * 5. updates systems required by new animation
		 * 
		 * Inactive slot - remove animation & its systems, removes from RigAnimation
		 * 
		 * Reload - apply current aniamtion to joints ( this is necessary when anothe rnaim slot becomes inactive )
		 * 
		 * @param	node
		 */
		private function updateNode(node:AnimationLoaderNode, time:Number):void
		{
			var rigAnim:RigAnimation = node.rigAnim;
			var creature:Creature = node.parent.parent.get( Creature );
			
			if ( rigAnim != null )
			{
				// check for animation change
				if ( rigAnim.next  && !rigAnim.waitForEnd)
				{				
					var animation:*;					
					// instantiated animation class, parse animation xml, and add to appropriate Dictionary, if not yet loaded
					if ( creature )
					{
						_animationLibrary.add( rigAnim.next, creature.variant );	// create animation class if not yet c
						animation = _animationLibrary.getAnimation( rigAnim.next, creature.variant );
					}
					else
					{
						_animationLibrary.add( rigAnim.next );
						animation = _animationLibrary.getAnimation( rigAnim.next );
					}
					
					if ( animation )	// animation is null if not library or has not completed loading
					{
						rigAnim.current = animation;	// NOTE :: setting current, sets next == null;
						node.animSlot.active = true;
						
						// reset Timeline
						resetTimeline( node ); 
						rigAnim.end = false;
						
						// check for nextDuration
						if ( rigAnim.nextDuration > 0 )
						{
							rigAnim.duration = rigAnim.nextDuration;
							rigAnim.nextDuration = 0;
						}
						
						// reset PartAnimationData for joints
						applyAnimationToParts( node );
						
						// remove previous animation from entity
						removeAnimation( rigAnim.previous, node.parent );
						
						// update sytems, removing and adding as necessary
						updateSystems( node );
					}	
				}
				else if ( !node.animSlot.active && rigAnim.current )	// check for active off
				{
					removeAnimation( rigAnim.current, node.parent );	// remove current animation from entity
					node.timeline.playing = false;						// stop timeline
					rigAnim.current = null;								// remove current, prevents deactivaton from happening repeatedly
				}
				else if ( node.animSlot.reload )							// check for reload
				{
					applyAnimationToParts( node );
					node.animSlot.reload = false;
				}
			}
		}

		private function applyAnimationToParts(node:AnimationLoaderNode):void
		{
			var joint:Joint;
			var partAnimData:PartAnimationData;
			var rigAnim:RigAnimation = node.rigAnim;
			
			// NOTE :: if no parts have been specifed, assume animation should be applied to all joints
			if ( rigAnim.partsApplied.length == 0 )
			{
				for each ( var jointEntity:Entity in node.rig.joints )
				{
					joint = jointEntity.get(Joint);
					if ( joint )
					{
						updateJoint( node, jointEntity, joint.id );
					}
				}
			}
			else
			{
				var partName:String;
				for ( var i:int = 0; i < rigAnim.partsApplied.length; i++ )
				{
					partName = rigAnim.partsApplied[i];
					updateJoint( node, node.rig.getJoint( partName ), partName );
				}
			}
		}
		
		private function updateJoint( node:AnimationLoaderNode, jointEntity:Entity, partName:String ):void
		{
			var partAnimData:PartAnimationData 	= node.rigAnim.current.data.getPart( partName );
			var partSlot:AnimationSlot	 		= jointEntity.get( AnimationSlot );
			var joint:Joint	 					= jointEntity.get( Joint );
			
			if ( partSlot == null )										// if nothing has been applied yet, apply all
			{
				resetJoint( node, jointEntity, joint, partAnimData );
			}
			else if ( !partSlot.active )								// if current slot is inactive, replace all
			{
				resetJoint( node, jointEntity, joint, partAnimData );
			}
			else
			{			
				if ( partSlot.priority == node.animSlot.priority )		// if slots are same, replace data
				{
					if ( joint.partAnimData != partAnimData )			// check that data is not the same
					{
						joint.partAnimData = partAnimData;
						joint.isSet = false;
					}
				}
				else if ( partSlot.priority < node.animSlot.priority )	// if new slot is of greater priority, replace all
				{
					resetJoint( node, jointEntity, joint, partAnimData );
				}
				// if new slot priorty is less than current slot, do nothing
			}
		}
		
		private function resetJoint( node:AnimationLoaderNode, jointEntity:Entity, joint:Joint, partAnimData:PartAnimationData ):void
		{
			joint.partAnimData = partAnimData;
			jointEntity.add( node.timeline );
			jointEntity.add( node.animSlot );
			joint.isSet = false;
		}
		
		private function resetTimeline( node:AnimationLoaderNode ):void
		{
			// reset Timeline for new animation
			node.timeline.data.frames 	= node.rigAnim.current.data.frames;
			node.timeline.data.duration = node.rigAnim.current.data.duration;
			node.timeline.reset();
		}
		
		private function removeAnimation(anim:Animation, parent:Parent):void
		{
			if ( anim != null)
			{
				anim.remove(parent.parent);
				
				/*
				// clean up any unused systems (TODO : necessary?  Cost of cleanup might exceed the cost of an empty system.
				if (previous.systems != null)
				{
					_game.updateComplete.addOnce(_game.removeInactiveSystems);
				}
				*/
			}
		}
		
		private function updateSystems(node:AnimationLoaderNode):void
		{
			var rigAnim:RigAnimation = node.rigAnim;

			// check to see if loaded animation class requires new systems, if so add them to _newSystems
			if ( rigAnim.current.systems != null)	
			{
				var newSystems:Array;
				
				if (rigAnim.previous != null)	
				{
					if (rigAnim.previous.systems == null) 
					{
						newSystems = rigAnim.current.systems;   
					} 
					else if ( !ArrayUtils.arraysEqual(rigAnim.current.systems, rigAnim.previous.systems))
					{
						newSystems = rigAnim.current.systems; 
					}
				}
				else
				{
					newSystems = rigAnim.current.systems;
				}
				
				if (newSystems != null)
				{
					// Duplicates are ok in this array, they'll get ignored and removed in addNewSystems.
					_newSystems = _newSystems.concat(newSystems);
				}
			}
			
			rigAnim.current.addComponentsTo(node.parent.parent);		// adds & sets components necessary for the animation to character entity
		}
		
		/**
		 * Queue new systems required by animation classes 
		 */
		private function addNewSystems():void
		{
			var systemClass:Class;
				
			// TODO : remove duplicate system entries first?
			while(_newSystems.length > 0)
			{
				systemClass = _newSystems.pop();

				if (!_groupManager.getSystem(systemClass))
				{				
					var system:System = new systemClass();
					
					_groupManager.addSystem(system);
				}
			}
		}
		
		//[Inject]
		private var _animationLibrary:AnimationLibrary;
		public function get animationLibrary():AnimationLibrary	{ return _animationLibrary; }

		[Inject]
		public var _shellApi:ShellApi;
		[Inject]
		public var _groupManager:GroupManager;
		private var _newSystems:Array;
	}
}
