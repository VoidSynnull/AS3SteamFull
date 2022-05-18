package game.systems.entity
{
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import engine.components.Id;
	
	import game.components.entity.character.part.eye.Eyes;
	import game.data.StateData;
	import game.data.character.part.eye.EyeBallData;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.EyeNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.DataUtils;
	import game.util.DisplayUtils;
	import game.util.GeomUtils;
	import game.util.SkinUtils;

	/**
	 * Manages eyes and pupils for characters.
	 * Eyes can vary in a number of ways;
	 * pupil position - the position of the pupils within th eyeball
	 * lid percent - how much the eye lid is closed or open
	 * lid line - the type of line associated with the lid, generally straight, but can vary for when lid is fully closed
	 */
	public class EyeSystem extends GameSystem
	{
		public function EyeSystem()
		{
			super( EyeNode, updateNode, nodeAddedFunction );
			super._defaultPriority = SystemPriorities.render;
			super.fixedTimestep = FixedTimestep.ANIMATION_TIME;
			super.linkedUpdate = FixedTimestep.ANIMATION_LINK;
			super.nodeAddedFunction = ESNodeAddedFunction;
		}
		
		private function ESNodeAddedFunction( node:EyeNode ):void
		{
			// assign assets
			node.eyes.applyDisplay( node.display.displayObject );
			updateEyeState( node );
			
			// update lashes based on gender
			var genderState:StateData = node.state.getState( SkinUtils.GENDER );
			if (genderState == null)
			{
				node.eyes.hasLashes = false;
			}
			else
			{
				node.eyes.hasLashes = ( genderState.value == SkinUtils.GENDER_FEMALE );
			}
		}
		
		/**
		 * Updates the state, color, and assets for eyes
		 * @param	node
		 */
		private function updateNode(node:EyeNode, time:Number):void
		{
			var eyes:Eyes = node.eyes;
			// set eye/pupils states if they have changed
			if ( node.state.hasChanged )	//check states set by skin ( gender )
			{
				var genderState:StateData = node.state.getState( SkinUtils.GENDER );
				eyes.hasLashes = ( genderState.value == SkinUtils.GENDER_FEMALE );
//				if( genderState.invalidate )
//				{
//					eyes.hasLashes = ( genderState.value == SkinUtils.GENDER_FEMALE );
//				}
				var eyeState:StateData = node.state.getState( SkinUtils.EYE_STATE );
				if( eyeState.invalidate )
				{
					eyes.state = eyeState.value;
					eyes._stateInvalidate = true;
				}
			}

			updateEyeState( node );
			
			// update/check for blink
			// if can blink, check for a random blink, check this before checking for invalidate
			if( eyes.state == BLINK || checkForBlink( node, eyes) )
			{
				updateBlink( node, eyes );	// when blink finishes it resets the state, while running sets active to true
			}
			
			// if pupils are following or were manually set position is updated
			//eyes and lids are fighting each other when lids want to be full or 0
			if(eyes.lidPercent < 100)
				updatePupilPosition( node, eyes );

			// update lids and lashes when eye state has changed or pupil is moving
			if ( eyes.requiresUpdate )		
			{
				//determine if lid/lash clips needs to update frames
				// NOTE :: This needs to be called before updateLid, as visible is used as flag
				updateLidLashStates( eyes );
				
				//determine if lid position needs to be updated
				updateLid( eyes );
	
				eyes.requiresUpdate = false;
			}
		}
		
		
		/////////////////////////////////////////////////////////////////////////
		///////////////////////////////  EYE STATE  /////////////////////////////
		/////////////////////////////////////////////////////////////////////////
		
		private function updateEyeState( node:EyeNode ):void
		{
			var eyes:Eyes = node.eyes;
			if( eyes._stateInvalidate )
			{
				setEyeState( node, eyes.state );
			}
			
			// set pupil state 
			// NOTE :: Call this after setting eye state, as it overrides some eye state settings
			if( eyes._pupilInvalidate )
			{
				applyPupilState( node );
			}
		}

		private function setEyeState( node:EyeNode, eyeState:String ):void
		{
			if ( DataUtils.validString( eyeState ) )
			{
				// if on card then force open still
				if ((node.parent.parent.has(Id)) && (node.parent.parent.get(Id).id == "cardDummy"))
				{
					eyeState = OPEN_STILL;
				}
				
				var eyes:Eyes = node.eyes;
	
				// reset pupil state
				eyes.pupilRadiusPercent = 1;	
				eyes.pupilsManual = false;

				switch(eyeState)
				{
					case SQUINT:
						eyes.lidLineState 	= OFF;
						eyes.lashState 		= STANDARD;
						eyes.lidFillState 	= STANDARD;
						eyes.lidPercent 	= 48.3;
						eyes.pupilsFollow 	= true;
						eyes.isLidFollow 	= true;
						eyes.isLashFollow 	= true;
						eyes.canBlink 		= true;
						break;
					case (SQUINT + STILL):
						eyes.lidLineState 	= OFF;
						eyes.lashState 		= STANDARD;
						eyes.lidFillState 	= STANDARD;
						eyes.lidPercent 	= 48.3;
						eyes.pupilsFollow 	= false;
						eyes.isLidFollow 	= true;
						eyes.isLashFollow 	= true;
						eyes.canBlink 		= false;
						eyes.pupilState		= CENTER;
						break;
					case OPEN:
						eyes.lidLineState 	= OFF;
						eyes.lashState 		= STANDARD;
						eyes.lidFillState 	= OFF;
						eyes.lidPercent 	= 0;
						eyes.pupilsFollow 	= true;
						eyes.isLidFollow 	= false;
						eyes.isLashFollow	= false;
						eyes.canBlink 		= true;
						break;
					case OPEN_CASUAL:		// open, but eyes don't follow
						eyes.lidLineState 	= OFF;
						eyes.lashState 		= STANDARD;
						eyes.lidFillState 	= OFF;
						eyes.lidPercent 	= 0;
						eyes.pupilsFollow 	= false;
						eyes.isLidFollow 	= false;
						eyes.isLashFollow	= false;
						eyes.canBlink 		= true;
						eyes.pupilState		= FRONT;
						break;
					case OPEN_STILL:		// can't blink
						eyes.lidLineState 	= OFF;
						eyes.lashState 		= STANDARD;
						eyes.lidFillState 	= OFF;
						eyes.lidPercent 	= 0;
						eyes.pupilsFollow 	= false;
						eyes.isLidFollow 	= false;
						eyes.isLashFollow	= false;
						eyes.canBlink 		= false;
						eyes.pupilState		= FRONT; // was CENTER
						break;
					case CASUAL:
						eyes.lidLineState 	= OFF;
						eyes.lashState 		= STANDARD;
						eyes.lidFillState 	= STANDARD;
						eyes.lidPercent 	= 31.4;
						eyes.pupilsFollow 	= false;
						eyes.isLidFollow 	= true;
						eyes.isLashFollow 	= true;
						eyes.canBlink 		= true;
						eyes.pupilState		= FRONT;
						break;
					case CASUAL_STILL:		// can't blink
						eyes.lidLineState 	= OFF;
						eyes.lashState 		= STANDARD;
						eyes.lidFillState 	= STANDARD;
						eyes.lidPercent 	= 31.4;
						eyes.pupilsFollow 	= false;
						eyes.isLidFollow 	= true;
						eyes.isLashFollow 	= true;
						eyes.canBlink 		= false;
						eyes.pupilState		= FRONT;
						break;
					case BLINK:
						eyes.lidLineState 	= OFF;
						eyes.lashState 		= LASHES_BLINK;
						eyes.lidFillState	= STANDARD;
						// lidPercent set during blink update
						eyes.pupilsFollow 	= false;
						eyes.isLidFollow	= true;
						eyes.isLashFollow 	= false;
						eyes.canBlink		= false;
						eyes.blinkIndex 	= 0;
						break;
					case LAUGH:
						eyes.lidLineState 	= LID_LAUGH;
						eyes.lashState 		= OFF;
						eyes.lidFillState 	= STANDARD;
						eyes.lidPercent 	= 100;
						eyes.pupilsFollow 	= false;
						eyes.isLidFollow 	= false;
						eyes.isLashFollow	= false;
						eyes.canBlink		= false;
						break;
					case CRY:
						eyes.lidLineState 	= OFF;
						eyes.lashState 		= LASHES_CRY;
						eyes.lidFillState 	= STANDARD;
						eyes.lidPercent 	= 100;
						eyes.pupilsFollow 	= false;
						eyes.isLidFollow 	= false;
						eyes.isLashFollow	= false;
						eyes.canBlink		= false;
						break;
					case ANGRY:
						eyes.lidLineState 	= LID_ANGRY;
						eyes.lashState 		= OFF;
						eyes.lidFillState 	= STANDARD;
						eyes.lidPercent 	= 100;
						eyes.pupilsFollow 	= false;
						eyes.isLidFollow 	= false;
						eyes.isLashFollow	= false;
						eyes.canBlink		= false;
						break;
					case CLOSED:
						eyes.lidLineState 	= OFF;
						eyes.lashState 		= LASHES_MID;
						eyes.lidFillState 	= STANDARD;
						eyes.lidPercent 	= 100;
						eyes.pupilsFollow 	= false;
						eyes.isLidFollow 	= false;
						eyes.isLashFollow	= false;
						eyes.canBlink		= false;
						break;
					case MEAN:
						eyes.lidLineState 	= OFF;
						eyes.lashState 		= STANDARD;
						eyes.lidFillState 	= LID_MEAN;
						eyes.lidPercent 	= 31.4;
						eyes.pupilsFollow 	= true;
						eyes.isLidFollow 	= true;
						eyes.isLashFollow 	= true;
						eyes.canBlink 		= true;
						break;
					case MEAN_STILL:
						eyes.lidLineState 	= OFF;
						eyes.lashState 		= STANDARD;
						eyes.lidFillState 	= LID_MEAN;
						eyes.lidPercent 	= 31.4;
						eyes.pupilsFollow 	= false;
						eyes.isLidFollow 	= true;
						eyes.isLashFollow 	= true;
						eyes.canBlink 		= false;
						break;
					case OPEN_MANUAL:
						eyes.lidLineState 	= OFF;
						eyes.lashState 		= STANDARD;
						eyes.lidFillState 	= OFF;
						eyes.lidPercent 	= 0;
						eyes.pupilsFollow 	= false;
						eyes.isLidFollow 	= false;
						eyes.isLashFollow	= false;
						eyes.canBlink 		= false;
						break;
					case CASUAL_MANUAL:
						eyes.lidLineState 	= OFF;
						eyes.lashState 		= STANDARD;
						eyes.lidFillState 	= STANDARD;
						eyes.lidPercent 	= 31.4;
						eyes.pupilsFollow 	= false;
						eyes.isLidFollow 	= true;
						eyes.isLashFollow 	= true;
						eyes.canBlink 		= false;
						break;
					case TALK:
						if( eyes.permanentState == EyeSystem.OPEN )
						{
							eyes.lidFillState 	= EyeSystem.OFF;
							eyes.lidPercent 	= 0;
							eyes.isLidFollow 	= false;
							eyes.isLashFollow	= false;
						}
						else if ( eyes.permanentState == EyeSystem.SQUINT )
						{
							eyes.lidFillState 	= EyeSystem.STANDARD;
							eyes.lidPercent 	= 30;
							eyes.isLidFollow 	= true;
							eyes.isLashFollow 	= true;
						}
						eyes.lidLineState 	= EyeSystem.OFF;
						eyes.lashState 		= EyeSystem.STANDARD;
						eyes.pupilsFollow 	= false;
						eyes.canBlink 		= false;		// TODO :: want to allow blinking, issue with locking from talk. - bard
						eyes.pupilState		= EyeSystem.FRONT;
						break;
					default:
						//trace("Error :: EyeData :: " + eyeState + " is not a valid state.");
						eyes.requiresUpdate = false;
						return;
						break;
				}
				
				eyes._stateInvalidate = false;
				eyes.requiresUpdate = true;
			}
			else
			{
				//trace("Error :: EyeData :: invalid state value: " + eyeState );
			}
		}

		/////////////////////////////////////////////////////////////////////////
		//////////////////////////////////  LID  ////////////////////////////////
		/////////////////////////////////////////////////////////////////////////
		
		/**
		 * Updates lid, lidline, & eyelash positions/scale
		 * @param	eyes
		 */
		private function updateLid( eyes:Eyes ):void
		{	
			var lids:MovieClip = eyes.lids;
			var lidLine:MovieClip = eyes.lidLine;
			var lashes:MovieClip = eyes.lashes;
			
			// check for off states
			if (( isNaN(eyes.lidPercent) ) || ( eyes.lidPercent == 0 ))			// if lid is fully open 
			{
				// hide both lidLine & lidFill
				lids.visible = false;
				if (lidLine != null)
					lidLine.visible = false;
				
				// position lashes
				if ((lashes != null) && (lashes.visible))
				{
					lashes.y = 0;
					lashes.rotation = 0;
				}
			}
			else
			{
				var position:Number;
				if ( eyes.lidPercent == 100 )	// if lid is fully closed
				{
					position = eyes.eye1.eyeball.y + eyes.eye1.eyeball.height;
					lids.visible = true;
					lids.rotation = 0;
					lids.y = position - LID_OFFSET;

					if ((lidLine != null) && (lidLine.visible))
					{
						if ( eyes.isLidFollow )	// if lidLine if following (which is on while tracking) hide
						{
							lidLine.visible = false;
						}
					}
					
					if ((lashes != null) && (lashes.visible))
					{
						lashes.rotation = 0;
						lashes.y = 0;
					}
				}
				else							// lid is neither fully open or fully closed  
				{
					position = eyes.eye1.eyeball.y + eyes.eye1.eyeball.height * eyes.lidPercent / 100;
					
					var rotation:Number = 0;
					if ( eyes.pupilsFollow )
					{
						rotation = getRotation( eyes );
					}
				
					if ( lids.visible )
					{
						lids.y = position - LID_OFFSET;
						lids.rotation = rotation;
					}
	
					if ((lashes != null) && (lashes.visible))
					{
						lashes.y = position - LID_OFFSET;
						lashes.rotation = rotation;						
					}
				}
			}
		}
		
		/**
		 * Determines the rotation of the lidline based on the lid percent (how open or closed the lid is)
		 * @param	eyes
		 * @return
		 */
		private function getRotation( eyes:Eyes ):Number
		{
			var rotation:Number = 0;
			if ( eyes.lidPercent < 50 )	// TODO : to make this a little more accurate, should adjust quadratically instead of linearly
			{
				rotation = (50 - eyes.lidPercent) / 50 * _lidRotationMaxUp;
			}
			else if ( eyes.lidPercent > 50 )
			{
				rotation = ((eyes.lidPercent - 50) / 50) * _lidRotationMaxDown;
			}
			return rotation;
		}
		
		/**
		 * Process the new state, for now we just set pices to the frames designnated by the EyeData
		 * @param	eyes
		 */
		private function updateLidLashStates(eyes:Eyes):void
		{
			if ( eyes._lashInvalidate )
			{
				eyes.lashes.visible = true;
				eyes.lashes.gotoAndStop( eyes.lashState );
				eyes._lashInvalidate = false;
			}

			if ( eyes._lidLineInvalidate )
			{
				eyes.lidLine.visible = true;
				eyes.lidLine.gotoAndStop( eyes.lidLineState );
				eyes._lidLineInvalidate = false;
			}
			
			if ( eyes._lidFillInvalidate )
			{
				eyes.lids.visible = true;
				eyes.lidFill.gotoAndStop( eyes.lidFillState );
				eyes.lidFillLine.gotoAndStop( eyes.lidFillState );
				eyes._lidFillInvalidate = false;
			}
		}
	
	/////////////////////////////////////////////////////////////////////////
	////////////////////////////////  PUPILS  ///////////////////////////////
	/////////////////////////////////////////////////////////////////////////

		/**
		 * Use the pupilState value to detemerine the angle & radius percentage of the pupil.
		 * Setting the pupil via pupilState turns pupilsManual on and pupilsFollow off.
		 * @param node
		 * 
		 */
		private function applyPupilState( node:EyeNode ):void
		{
			var eyes:Eyes = node.eyes;
			var pupilState:* = eyes.pupilState;
			var angle:Number = Number(pupilState);
			
			if ( isNaN(angle) )	// if data is String set pupil angle from string value
			{
				setPupilByState( eyes, String(pupilState) )
			}
			else
			{
				eyes.pupilAngle = angle;
			}
		}
		
		private function setPupilByState( eyes:Eyes, pupilState:String ):void
		{
			switch( pupilState )
			{
				case UP:
					eyes.pupilAngle = 90;
					eyes.pupilRadiusPercent = 1;
					break;
				case DOWN:
					eyes.pupilAngle = 270;
					eyes.pupilRadiusPercent = 1;
					break;
				case FRONT:
					eyes.pupilAngle = 360;
					eyes.pupilRadiusPercent = 1;
					break;
				case BACK:
					eyes.pupilAngle = 180;
					eyes.pupilRadiusPercent = 1;
					break;
				case CENTER:
					eyes.pupilAngle = 360;
					eyes.pupilRadiusPercent = 0;
					break;
				default:
					trace("Error :: EyeSystem :: " + pupilState + " is not a valid state.");
					//eyes._pupilAngle = 360;
					//eyes.pupilRadiusPercent = 1;
					break;
			}
		}
		
		/**
		 * Updates the pupil positions for the eyes
		 * @param	eyes
		 */
		private function updatePupilPosition( node:EyeNode, eyes:Eyes ):void
		{
			if ( eyes._pupilInvalidate )	// if the position specified update it, otherwise do not reposition pupil
			{
				var radian:Number = GeomUtils.degreeToRadian( eyes.pupilAngle );
				positionPupil( eyes, eyes.eye1, radian );
				positionPupil( eyes, eyes.eye2, radian );
				eyes.lidPercent = getLidPercent( eyes );
				
				eyes.pupilsManual = true;
				eyes._pupilInvalidate = false;
				eyes.requiresUpdate = true;
			}
			else if ( eyes.pupilsFollow )
			{
				var eyeData:EyeBallData;
				var targetX:Number;
				var targetY:Number;
				//var targetSpatial:TargetSpatial = node.target;

				// TODO :: target is not relative to position of eyeball, should make some lower level functionality that handled postion relativity
				eyeData = eyes.eye2;
				var localTarget:Point;
				if( eyes.targetDisplay )
				{
					localTarget = DisplayUtils.localToLocal( eyes.targetDisplay, eyeData.eyeball );
					targetX = localTarget.x;
					targetY = localTarget.y;
					//trace("Eyes: follow spatial target: " + targetX + ", " + targetY );
				}
				else
				{
					targetX = eyeData.eyeball.mouseX;
					targetY = eyeData.eyeball.mouseY;
					//trace("Eyes: follow mouse target: " + targetX + ", " + targetY );
				}
				positionPupil( eyes, eyeData, GeomUtils.radiansBetween( targetX, targetY, eyeData.eyeball.x, eyeData.eyeball.y ));
				
				eyeData = eyes.eye1;
				if( eyes.targetDisplay )
				{
					localTarget = DisplayUtils.localToLocal( eyes.targetDisplay, eyeData.eyeball );
					targetX = localTarget.x;
					targetY = localTarget.y;
				}
				else
				{
					targetX = eyeData.eyeball.mouseX;
					targetY = eyeData.eyeball.mouseY;
				}
				positionPupil( eyes, eyeData, GeomUtils.radiansBetween( targetX, targetY, eyeData.eyeball.x, eyeData.eyeball.y ));
				
				eyes.lidPercent = getLidPercent( eyes );
				eyes.requiresUpdate = true;
			}
		}
		
		private function getLidPercent( eyes:Eyes ):Number
		{
			var eyeData:EyeBallData = eyes.eye2;
			return ( eyeData.eyeball.height / 2 + eyeData.pupil.y - eyeData.pupil.height / 2) / eyeData.eyeball.height * 100;
		}
		
		/**
		 * Positions the pupil within its eyeball
		 * @param	eye
		 * @param	radian
		 */
		private function positionPupil( eyes:Eyes, eye:EyeBallData, radian:Number ):void
		{
			eye.pupil.x = eye.pupilCenter.x + Math.cos(radian) * -(eye.pupilRange * eyes.pupilRadiusPercent);
			eye.pupil.y = eye.pupilCenter.y + Math.sin(radian) * -(eye.pupilRange * eyes.pupilRadiusPercent);
		}
	
	/////////////////////////////////////////////////////////////////////////
	////////////////////////////////  BLINK  ////////////////////////////////
	/////////////////////////////////////////////////////////////////////////
		
		/**
		 * Checks for blink, which is called randomly
		 * @param	eyes
		 */
		private function checkForBlink( node:EyeNode, eyes:Eyes ):Boolean
		{
			// TODO :: would be nice to have a wait, so that blinks have a default pause between them, so they can't happen in rapid succession
			if (( Math.random() * eyes.blinkChance) <= 1 && eyes.canBlink)
			{
				eyes.previousStore();
				eyes.state = BLINK;
				setEyeState( node, BLINK );
				return true;
			}
			return false;
		}

		
		/**
		 * Updates blinking once it is made active, also determines when blink is complete
		 * @param eyes
		 * @return - Boolean if blink is complete, used to determine if eye positioning needs to be updated
		 * 
		 */
		private function updateBlink( node:EyeNode, eyes:Eyes):void
		{
			if ( eyes.blinkIndex < eyes.blinkSequence.length )
			{
				eyes.lidPercent = eyes.blinkSequence[eyes.blinkIndex];
				// lashes start at BLINK, once almost closed go to CRY, on the way back up they are in MID
				if( eyes.lidPercent > 80 )
				{
					if( eyes.lashState == LASHES_BLINK )
					{
						eyes.lashState = LASHES_CRY;
					}
				}
				else if( eyes.lashState = LASHES_CRY )
				{
					eyes.lashState = LASHES_MID;
				}
				eyes.blinkIndex++;
				eyes.requiresUpdate = true;	
			}
			else	// blink is complete, return to previous state	
			{
				// if pet then force eyelid open
				if (eyes.isPet)
				{
					eyes.lidPercent = 1;
				}
				eyes.previousApply();
				updateEyeState( node );
			}
		}
		
		private const LID_OFFSET:int = 25;
		
		// shared across eye, lid, lidFill, & lash states
		public static const OFF:String 			= "off";
		public static const STANDARD:String 	= "standard";
		public static const STILL:String 		= "_still";
		
		// eye states
		public static const ANGRY:String 		= "angry";
		public static const MEAN:String 		= "mean";
		public static const MEAN_STILL:String 	= "mean_still";
		public static const BLINK:String 		= "blink";
		public static const CASUAL:String 		= "casual";
		public static const CASUAL_STILL:String = "casual_still";
		public static const CLOSED:String 		= "closed";
		public static const CRY:String 			= "cry";
		public static const DUMMY:String 		= "dummy";
		public static const LAUGH:String 		= "laugh";
		public static const OPEN:String			= "open";
		public static const OPEN_CASUAL:String	= "open_casual";
		public static const OPEN_STILL:String	= "open_still";
		public static const SQUINT:String 		= "squint";
		public static const MANUAL:String 		= "manual_on";	// state has been augmented (by manually setting pupils)
		public static const TALK:String 		= "talk";
		public static const OPEN_MANUAL:String	= "open_manual";
		public static const CASUAL_MANUAL:String = "casual_manual";
		
		// lid & lid fill states
		private const LID_MEAN:String 		= "mean";		// also for lid fill
		private const LID_LAUGH:String 		= "laugh";
		private const LID_ANGRY:String 		= "angry";
		private const LID_CLOSED:String 	= "closed";

		private const _lidRotationMaxUp:int = -11;
		private const _lidRotationMaxDown:int = 6;
		
		// lash states
		private const LASHES_BLINK:String 		= "blink";
		private const LASHES_CRY:String 		= "cry";
		private const LASHES_MID:String 		= "mid";
		
		//pupils states
		public static const UP:String 			= "up";
		public static const BACK:String 		= "back";
		public static const DOWN:String 		= "down";
		public static const FRONT:String 		= "front";
		public static const CENTER:String 		= "center";
		
		
	}
}
