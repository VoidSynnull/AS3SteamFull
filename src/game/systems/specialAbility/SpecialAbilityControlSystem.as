package game.systems.specialAbility
{
	import flash.external.ExternalInterface;
	import flash.utils.Dictionary;
	
	import ash.core.NodeList;
	import ash.tools.ListIteratingSystem;
	
	import engine.ShellApi;
	import engine.components.Id;
	import engine.util.Command;
	
	import game.components.specialAbility.SpecialAbilityControl;
	import game.data.ParamData;
	import game.data.TimedEvent;
	import game.data.specialAbility.SpecialAbility;
	import game.data.specialAbility.SpecialAbilityData;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scenes.hub.starcade.Starcade;
	import game.systems.SystemPriorities;
	import game.systems.actionChain.ActionChain;
	import game.ui.hud.Hud;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	
	/**
	 * Applies animations to a rig.
	 * Processes the animation slot entities.
	 * Checks for a next aniamtion, and applies that animation to the rig
	 * Checks for inactive slots &amp; removes them
	 * Checks for relaod, which reapplies the current animations data tot the joints
	 */
	public class SpecialAbilityControlSystem extends ListIteratingSystem
	{
		public function SpecialAbilityControlSystem()
		{
			super( SpecialAbilityNode, updateNode, null, nodeRemoved );
			super._defaultPriority = SystemPriorities.update;
			_touchControls = PlatformUtils.isMobileOS;
		}
		
		private function nodeRemoved(node:SpecialAbilityNode):void
		{
			/*
			Make sure that all Special Abilities get deactivated if...
			1. The Node is removed
			2. The System is removed
			*/
			for each(var data:SpecialAbilityData in node.specialControl.specials)
			{
				if(data.specialAbility)
				{
					data.specialAbility.deactivate(node);
				}
			}
		}
		
		private function updateNode(node:SpecialAbilityNode, time:Number):void
		{
			var control:SpecialAbilityControl = node.specialControl;
			var specialData:SpecialAbilityData;
			
			if ( control != null )
			{
				if ( control._invalidate )
				{		
					if ( control.specials.length > 0 )
					{
						var isPlayer:Boolean = (node.player != null);
						var i:uint = 0;
						
						for ( i; i < control.specials.length; i++ )
						{
							specialData = control.specials[i];
							
							// if triggerable needs trigger to activate
							if ( specialData.triggerable )
							{
								if( control.trigger )
								{
									specialData.activate = true;
									
									if( control.userActivated )
									{
										userTriggered(node, specialData);
										control._invalidate = false;
									}
								}
							}
							
							if ( specialData.removeFlag )
							{
								if ( specialData.specialAbility )
								{
									// If using action button, remove
									if( specialData.useActionBtn && isPlayer )
									{
										removeActionButton( control, specialData );
									}
									
									specialData.specialAbility.removeSpecial( node );
								}
								control.specials.splice( i, 1 );
								i--;
								continue;
							}
							else if ( specialData._invalidate )	// if specialData has been activated
							{
								// active has changed, turn on or off depending on active
								if ( specialData.activate )
								{
									var init:Boolean = false;
									
									// instantiate SpecialAbility if null
									if ( specialData.specialAbility == null )
									{
										// Wrapping in a try/catch block in the event that a special ability class doesn't exist here.
										try
										{
											specialData.specialAbility = new specialData.specialClass();
											trace("SpecialAbilityControlSystem: ability: " + specialData.specialAbility);
											
											// if class created then set init flag
											if (specialData.specialAbility)
												init = true;
											
										} 
										catch(error:Error) 
										{
											trace("ERROR :: SpecialAbilityControlSystem :: The special ability class " + specialData.specialClass + " is either null, doesn't exist, or isn't being added to a class manifest.");
										}
									}
									
									// if initing
									if (init)
									{
										// Check need for action button, should only be displayed for player
										if((specialData.useActionBtn) && (isPlayer) )
											addActionButton( control, specialData );
										
										specialData.specialAbility.data = specialData;	// NOTE :: assign data before calling init()									
										specialData.specialAbility.init( node );
									}
									
									//var actionsGroup:ActionsGroup = this.group.shellApi.currentScene.getGroupById(ActionsGroup.GROUP_ID) as ActionsGroup;
									var actionChain:ActionChain;
									
									if(specialData.actionsGroup)
									{
										specialData.actionsGroup.setupGroup(node.owning.group);
										var dict:Dictionary = new Dictionary();
										dict["entity"] = node.entity;
										
										// rlh: prevents actions from triggering on cards in inventory
										var forceCardAction:Boolean = false;
										var data:ParamData = specialData.params.getParamId("applyToCard");
										if ((data != null) && (data.value == "true"))
										{
											forceCardAction = true;
										}
										if ((specialData.specialAbility.entity.get(Id).id != "cardDummy") || (forceCardAction))
										{
											trace("SpecialAbilityControlSystem: has action chain: " + specialData.id);
											if (specialData.id)
												actionChain = specialData.actionsGroup.getActionChain(SpecialAbilityData.BEFORE_ACTIONS_ID + "_" + specialData.id, dict);
											else
												actionChain = specialData.actionsGroup.getActionChain(SpecialAbilityData.BEFORE_ACTIONS_ID, dict);
										}
									}
									
									// if triggerable needs trigger to activate, otherwise activates automatically
									if(specialData.specialAbility)
									{
										if (specialData.triggerable)
										{
											if (control.trigger)
											{
												if(actionChain && _sfCount < 1)
												{
													actionChain.execute(Command.create(activateAbilityAfterActions, specialData, node), node);
													_sfCount++;
													if(_sfCount >= 1)
														SceneUtil.addTimedEvent(_shellApi.currentScene,new TimedEvent(specialData.sfPauseTimer,1,resetSFCount));
													continue;
												}
												// activate ability if not suppressed
												if (!specialData.specialAbility.suppressed)
												{
													if(_shellApi.smartFox.isConnected && _sfCount < 1)
													{
														specialData.specialAbility.activate( node );
														_sfCount++;
														if(_sfCount >= 1)
															SceneUtil.addTimedEvent(_shellApi.currentScene,new TimedEvent(specialData.sfPauseTimer,1,resetSFCount));
													}
													else
													{
														specialData.specialAbility.activate( node );
													}
												}
											}
										} 
										else 
										{
											if(actionChain)
											{
												actionChain.execute(Command.create(activateAbilityAfterActions, specialData, node), node);
												continue;
											}
											// activate ability if not suppressed
											if (!specialData.specialAbility.suppressed)
												specialData.specialAbility.activate( node );
										}
									}
									else if(actionChain) // we only have an action chain
									{										
										actionChain.execute();
									}
									
									if(specialData.specialAbility)
									{
										if((specialData.specialAbility as SpecialAbility).specialClassLoaded)
										{
											(specialData.specialAbility as SpecialAbility).specialClassLoaded.addOnce(specialClassLoaded);
										}
										else
										{
											specialData.fullyLoaded.dispatch(specialData);
										}
									}
								}
								else
								{
									if(specialData.specialAbility)
									{
										specialData.specialAbility.deactivate( node );
										_sfCount = 0;
									}
									else
									{
										trace("ERROR::  SpecialAbilityControlSystem:: specialAbility shouldn't be null")
									}
								}
								specialData._invalidate = false;
							}
						}
					}
					control.trigger = false;
					control._invalidate = false;
					
				}
			}
			
			if ( control.specials.length > 0 )
			{
				for ( var j:uint; j < control.specials.length; j++ )
				{
					specialData = control.specials[j];
					// update special ability
					if(specialData.isActive)
					{
						specialData.specialAbility.update(node, time);
					}
					
					// if trigger tracking is pending continue to increment time so that tracking eventually gets called
					if( specialData.trackPending )	
					{
						trackTrigger( specialData, time );
					}
				}
			}
		}
		private function resetSFCount():void
		{
			_sfCount = 0;
			
		}
		private function activateAbilityAfterActions(chain:ActionChain, data:SpecialAbilityData, node:SpecialAbilityNode):void
		{
			// activate ability if not suppressed
			if (!data.specialAbility.suppressed)
			{
				data.specialAbility.activate(node);
				data._invalidate = false;
			}
		}
		
		/////////////////////////////////////////// TOUCH CONTROLS ONLY ///////////////////////////////////////////
		
		// QUESTION :: Eventually may want to use part art within button? -bard
		/**
		 * MOBILE ONLY - Connects hud Action button to special ability trigger 
		 * @param specialControl
		 * @param specialData
		 */
		public function addActionButton( specialControl:SpecialAbilityControl, specialData:SpecialAbilityData ):void
		{
			trace("add action button");
			var hud:Hud = super.group.getGroupById( Hud.GROUP_ID ) as Hud;
			trace("not the issue i hope");
			if( hud )
			{
				trace("hud exists");
				// if SpecialAbilityControl doesn't have any abilities triggered by Action button yet, then add listen
				if( !specialControl.hasActionBtnUsers )
				{
					hud.addActionButtonHandler( specialControl.onTrigger );
				}
				specialControl.addActionBtnUser( specialData.type );
			}
		}
		
		/**
		 * MOBILE ONLY - Removes ability from list trigger via Action button
		 * If there are no remaining abilitoes listen for Action Button then we remove Action button from hud
		 * @param specialControl
		 * @param specialData
		 */
		private function removeActionButton( specialControl:SpecialAbilityControl, specialData:SpecialAbilityData ):void
		{
			specialControl.removeActionBtnUser( specialData.type );	
			if( !specialControl.hasActionBtnUsers )	// if no else is using action buttn, remove
			{
				var hud:Hud = super.group.getGroupById( Hud.GROUP_ID ) as Hud;
				if( hud )
				{
					// need to check if pop follower has action button on mobile
					if (_touchControls)
					{
						var nodeList:NodeList = super.systemManager.getNodeList( SpecialAbilityNode );
						for( var saNode:SpecialAbilityNode = nodeList.head; saNode; saNode = saNode.next )
						{
							var control:SpecialAbilityControl = saNode.specialControl;
							for ( var i:int; i < control.specials.length; i++ )
							{
								var sData:SpecialAbilityData = control.specials[i];
								// if has special action button, then skip out
								// applies to followers and pop followers
								if(sData.specialAbility)
								{
									if (sData.specialAbility._useSpecialActionBtn)
									{
										return;
									}
								}
							}
						}
					}

					// for now just remove button, may want to be more accomodating for other usage in future
					hud.removeActionButton();
				}
			}
			else									
			{
				// TODO :: if action button still in use, update display (Will implement later)
			}
		}
		
		////////////////////////////////////// TRACKING TRIGGER //////////////////////////////////////
		
		/**
		 * Called when special ability is triggered by user.
		 * In this case may want special handling (tracking for instance)
		 * @param node
		 * 
		 */
		private function userTriggered(node:SpecialAbilityNode, specialData:SpecialAbilityData):void
		{
			// if TrackingData defined, track ability usage
			if( specialData.trackData != null )
			{
				specialData.numTriggers++;
				specialData.trackPending = true;
			}
		}
		
		/**
		 * Track special ability triggering by the user.
		 * To prevent spamming the backend we accumulate trigger usage within a window of time
		 * The total number of triggers is sent when that time window has elapsed
		 * @param specialData - SpecialAbilityData being tracked
		 * @param time - time since last update in seconds
		 */
		private function trackTrigger( specialData:SpecialAbilityData, time:Number):void
		{
			// increment count of triggers
			specialData.timeSinceTrigger += time;
			
			// make sure no tracking timer is running
			// or force tracking is enabled
			if (( specialData.timeSinceTrigger > TRIGGER_WINDOW ) || (specialData.forceTracking))
			{
				var event:String = ( _touchControls ) ? TRACKING_ACTION_BTN_TRIGGER : TRACKING_SPACE_BAR_TRIGGER;
				
				// get number of triggers
				var triggerCount:String;
				if (specialData.numTriggers > 1)
					triggerCount = String(specialData.numTriggers);
				
				// if campaign
				if (specialData.trackData.campaign)
					_shellApi.adManager.track( specialData.trackData.campaign, event, specialData.trackData.choice, specialData.trackData.subChoice, null, NaN, triggerCount);
				else
					_shellApi.track( event, specialData.trackData.choice, specialData.trackData.subChoice, null, null, NaN, triggerCount);
				
				specialData.numTriggers = 0;
				specialData.timeSinceTrigger = 0;
				specialData.trackPending = false;
			}
		}
		
		private function specialClassLoaded(data:SpecialAbilityData):void
		{
			data.fullyLoaded.dispatch(data);
		}
		
		private const TRIGGER_WINDOW:Number = 5; // in seconds, window of time to gather triggers before sending tracking call
		
		[Inject]
		public var _shellApi:ShellApi;
		
		public static const TRACKING_SPACE_BAR_TRIGGER:String = "TriggerSpaceBar";
		public static const TRACKING_ACTION_BTN_TRIGGER:String = "TriggerActionBtn";
		
		private var _touchControls:Boolean = false;
		private var _sfCount:Number = 0;
	}
}
