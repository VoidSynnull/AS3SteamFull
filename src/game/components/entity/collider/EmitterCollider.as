package game.components.entity.collider
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import game.components.Emitter;
	import game.data.scene.hit.EmitterHitData;
	import game.data.sound.SoundAction;
	import game.particles.emitter.characterAnimations.Dust;
	
	public class EmitterCollider extends Component
	{
		public var active:Boolean;
		public var impactEmitter:Entity;
		public var impactEmission:Emitter;
		public var stepEmitter:Entity;
		public var stepEmission:Emitter;
		
		private var _action:String;
		private var _emitterHitData:EmitterHitData;
		private var _createNewEmitter:Boolean = false;
		
		
		public function setEmitterData( emitterHitData:EmitterHitData, action:String, useDefault:Boolean = false ):void
		{
			_action = action;
			createNewEmitter = false;
			
				// Don't do anything if there is no emitter hit data on that platform
			if( emitterHitData )
			{
				if( _emitterHitData )
				{
						// Determine which type of action to take and determine if the class
						// and parameters match
						// If they do not, set the flag to create a new emitter
					switch( action )
					{
						case SoundAction.IMPACT:
							if( emitterHitData.impactClass == _emitterHitData.impactClass )
							{
								if( emitterHitData.impactParams && _emitterHitData.impactParams )
								{
									if( emitterHitData.impactParams != _emitterHitData.impactParams )
									{
										_emitterHitData.impactParams = emitterHitData.impactParams;
										createNewEmitter = true;
									}
								}
								else if( !impactEmission )
								{
									createNewEmitter = true;
								}
							}
							else
							{
								_emitterHitData.impactClass = emitterHitData.impactClass;
								_emitterHitData.impactParams = emitterHitData.impactParams;
								createNewEmitter = true;
							}
							break;
						
						case SoundAction.STEP:
							if( emitterHitData.stepClass == _emitterHitData.stepClass )
							{
								if( emitterHitData.stepParams && _emitterHitData.stepParams )
								{
									if( emitterHitData.stepParams != _emitterHitData.stepParams )
									{
										_emitterHitData.stepParams = emitterHitData.stepParams;
										createNewEmitter = true;
									}
								}
								else if( !stepEmission )
								{
									createNewEmitter = true;
								}
							}
							else 
							{
								_emitterHitData.stepClass = emitterHitData.stepClass;
								_emitterHitData.stepParams = emitterHitData.stepParams;
								createNewEmitter = true;
							}
							break;
					}
				}
				else
				{
					_emitterHitData = emitterHitData;
					createNewEmitter = true;
				}
				
				active = true;
			}
			
			else if( useDefault )
			{
				if( !_emitterHitData )
				{
					_emitterHitData = new EmitterHitData();
				}
				
				if( _emitterHitData.stepClass != Dust )
				{
					_emitterHitData.stepClass = Dust;
					_emitterHitData.stepParams = null;
					createNewEmitter = true;
				}
				
				active = true;
			}
		}
		
		public function set createNewEmitter( create:Boolean ):void
		{
			_createNewEmitter = create;
		}
		
		public function get createNewEmitter():Boolean
		{
			return _createNewEmitter;
		}
		
		public function set emitterHitData( emitterHitData:EmitterHitData ):void
		{
			_emitterHitData = emitterHitData;
		}
		
		public function get emitterHitData():EmitterHitData 
		{
			return _emitterHitData;
		}
		
		public function set action( action:String ):void
		{
			_action = action;
		}
		
		public function get action():String
		{
			return _action;
		}
		
			// Set the emission types so we can avoid using .get in the system
		public function setEmission( entity:Entity, action:String ):void
		{
			var emitter:Emitter = entity.get( Emitter );
			
			switch( action )
			{
				case SoundAction.IMPACT:
					impactEmission = emitter;
					break;
				
				case SoundAction.STEP:
					stepEmission = emitter;
					break;
			}
		}
	}
}