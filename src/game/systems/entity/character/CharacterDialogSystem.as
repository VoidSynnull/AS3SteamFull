package game.systems.entity.character
{
	import com.greensock.easing.Bounce;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Engine;
	import ash.core.Entity;
	
	import engine.ShellApi;
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialOffset;
	import engine.components.Tween;
	import engine.group.Group;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.CharacterWander;
	import game.components.motion.Edge;
	import game.components.motion.GroupSpatialOffset;
	import game.components.ui.FloatingToolTip;
	import game.components.ui.WordBalloon;
	import game.creators.ui.ToolTipCreator;
	import game.creators.ui.WordBalloonCreator;
	import game.data.scene.characterDialog.Conversation;
	import game.data.scene.characterDialog.DialogData;
	import game.data.scene.characterDialog.DialogParser;
	import game.data.scene.characterDialog.Exchange;
	import game.nodes.entity.DialogNode;
	import game.systems.GameSystem;
	import game.systems.scene.SceneDialogSystem;
	import game.util.AudioUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	public class CharacterDialogSystem extends GameSystem
	{
		public var defaultDialogContainer:DisplayObjectContainer;
		public var cameraLimits:Rectangle;
		
		private var _balloonCreated:Signal = new Signal();
		private var _wordBalloonCreator:WordBalloonCreator = new WordBalloonCreator();
		private var _paused:Boolean = false;
		
		private const CHOICE_BALLOON_PATH:String = "ui/elements/characterDialogChoiceBalloon.swf";
		private const BALLOON_PATH:String = "ui/elements/wordBalloon.swf";
		public static const QUESTION_OFFSET:Number = 50;
		private const BALLOON_TWEEN_DURATION:Number = .4;
		
		public function CharacterDialogSystem()
		{
			super(DialogNode, updateNode);
		}
		
		public function set paused(state:Boolean):void {_paused = state;}
		
		public function updateNode(node:DialogNode, time:Number):void
		{
			if (_paused)
				return;
			
			if(node.dialog._sayCurrent)
			{
				displayDialog(node, node.dialog.current);
				node.dialog._sayCurrent = false;
			}
			else if(node.dialog._manualSay != null)
			{
				displayDialog(node, node.dialog._manualSay);
				node.dialog._manualSay = null;
			}
			else if(!node.dialog.speaking && !node.dialog.initiated && node.dialog.stoppedToListen)
			{
				node.dialog.stoppedToListen = false;
				var wander:CharacterWander = node.entity.get(CharacterWander);
				if(wander && wander.pause)
				{
					wander.pause = false; 
				}
			}
		}
		
		private function displayDialog(node:DialogNode, dialogData:*):void
		{
			if(dialogData != null)
			{
				if(typeof(dialogData) == "string")
				{
					var dialogText:String = dialogData;
					
					dialogData = node.dialog.getDialog(dialogText);
					
					if(dialogData == null)
					{
						dialogData = new DialogData();
						DialogData(dialogData).dialog = dialogText;
						DialogData(dialogData).type = DialogParser.STATEMENT;
						DialogData(dialogData).showDialog = true;
					}
				}
				else if(dialogData is DialogData && dialogData.dialogSet != null)
				{
					dialogData = dialogData.dialogSet[GeomUtils.randomInt(0, dialogData.dialogSet.length - 1)];
				}
				
				var speaker:Entity
				// position speaking entity towards player (if faceSpeaker is true)
				if(dialogData is Conversation)
				{
					speaker = (dialogData.forceSpeaker) ? node.owningGroup.group.getEntityById(dialogData.entityId) : _shellApi.player;
				}
				else
				{
					speaker = _shellApi.player;
				}
			
				if ( node.dialog.faceSpeaker && speaker )
				{
					if( speaker != node.entity)
					{
						var speakerSpatial:Spatial = speaker.get(Spatial);
						var answerSpatial:Spatial = node.entity.get(Spatial);
						var scale:Number = answerSpatial.scale;
						
						if (answerSpatial.x < speakerSpatial.x)
						{
							scale = -answerSpatial.scale;
						}
						
						answerSpatial.scaleX = scale;
					}
				}
				
				if(dialogData is DialogData)
				{
					if(!node.dialog.speaking || node.dialog.allowOverwrite)
					{
						node.dialog.speaking = true;
						node.dialog.initiated = false;
						this.displayStatement(node.entity, dialogData);
					}
				}
				else if(dialogData is Conversation)
				{
					if(!Dialog(speaker.get(Dialog)).speaking)	// player isn't already speaking
					{
						if( checkMotionLimit( speaker ) )		// player isn't moving too much
						{
							Dialog(speaker.get(Dialog)).speaking = true;
							Dialog(speaker.get(Dialog)).initiated = false;
							this.displayQuestions(node.entity, speaker, dialogData);
						}
					}
				}
			}
		}
		
		public function displayStatement( target:Entity, dialogData:DialogData ):void
		{
			Dialog(target.get(Dialog)).speaking = true;
			Dialog(target.get(Dialog)).initiated = false;
			if(Dialog(target.get(Dialog)).allowOverwrite)
			{
				EntityUtils.removeAllWordBalloons(target.group, target);
			}
			loadWordBalloon(target, dialogData);
		}
		
		public function displayQuestions( answerTarget:Entity, questionTarget:Entity, conversation:Conversation ):void
		{
			// if only 1 questions option, skip question chose and go directly to answer
			if(conversation.questions.length == 1)
			{	
				var answerComplete:Function = Command.create( handleChosenQuestionBubbleRemoved, Exchange(conversation.questions[0]).answer, answerTarget  )
				_balloonCreated.addOnce( Command.create(handleChosenBalloonCreated, answerComplete) );	// listen for next word balloon to be created, on that creation 
				
				displayStatement(questionTarget, Exchange(conversation.questions[0]).question);
				return;
			}
			
			//_questionBalloons = new Vector.<Entity>;
			this.group.shellApi.loadFile(this.group.shellApi.assetPrefix + CHOICE_BALLOON_PATH, createQuestionBalloon, questionTarget, answerTarget, conversation, 0);
		}
		
		private function createQuestionBalloon(asset:DisplayObjectContainer, questionTarget:Entity, answerTarget:Entity, conversation:Conversation, index:int, balloonEntities:Vector.<Entity> = null):void
		{
			var disp:Display
			var exchange:Exchange = conversation.questions[index];
			var offset:Point = getBalloonOffset( questionTarget );
			var balloonEntity:Entity;
			var groupSpatialOffset:GroupSpatialOffset;
			
			var dialog:Dialog = questionTarget.get(Dialog);
			//var dialogContainer:DisplayObjectContainer = dialog.container ? dialog.container : this.defaultDialogContainer;
			var dialogContainer:DisplayObjectContainer = defaultDialogContainer;
			
			balloonEntity = _wordBalloonCreator.createEntity(dialogContainer.addChild(asset) as MovieClip, questionTarget, exchange.question, offset, answerTarget, exchange.answer, this.group.shellApi.profileManager.active.dialogSpeed, true, cameraLimits);
			asset["bg"].stop();
			EntityUtils.visible( balloonEntity, false, true );
			
			// first balloon entity should be give GroupSpatialOffset
			if( balloonEntities == null)
			{
				balloonEntities = new Vector.<Entity>();
				groupSpatialOffset = new GroupSpatialOffset();
				balloonEntity.add(groupSpatialOffset);
			}
			else
			{
				groupSpatialOffset = balloonEntities[0].get(GroupSpatialOffset);
				if( groupSpatialOffset != null )
				{
					balloonEntity.add(groupSpatialOffset);
				}
			}
			
			if( groupSpatialOffset != null )
			{
				groupSpatialOffset.offsets.push(balloonEntity.get(SpatialOffset));
			}
			
			var interaction:Interaction = balloonEntity.get(Interaction);
			interaction.down.addOnce(Command.create(handleQuestionDown, questionTarget, balloonEntities));
			interaction.up.addOnce(handleQuestionUp);
			interaction.over.add(handleQuestionOver);
			interaction.out.add(handleQuestionOut);
			
			balloonEntities.push( balloonEntity );
			
			// Check load next question
			if (index < conversation.questions.length - 1) 
			{
				this.group.shellApi.loadFile(this.group.shellApi.assetPrefix + CHOICE_BALLOON_PATH, createQuestionBalloon, questionTarget, answerTarget, conversation, index+1, balloonEntities);
			} 
			else 
			{
				allQuestionBalloonsLoaded( offset, balloonEntities, questionTarget.group )
			}
		}
		
		private function allQuestionBalloonsLoaded( offset:Point, balloonEntities:Vector.<Entity>, group:Group ):void 
		{
			var balloonEntity:Entity;
			var spatial:Spatial
			var spatialOffset:SpatialOffset
			var display:Display
			var prevSpatial:Spatial;
			var previousSpatialOffset:SpatialOffset
			var prevDisplay:Display
			var tween:Tween;
			
			var i:int
			for (i = 0; i < balloonEntities.length ; i++)
			{
				balloonEntity 	= balloonEntities[i];
				spatial 		= balloonEntity.get(Spatial) as Spatial
				spatialOffset 	= balloonEntity.get(SpatialOffset) as SpatialOffset
				display 		= balloonEntity.get(Display) as Display
				
				if (i == 0) 
				{
					spatialOffset.y -= QUESTION_OFFSET;
				}
				else 
				{
					display.displayObject["line"].visible = false;
					spatialOffset.y = previousSpatialOffset.y - prevDisplay.displayObject["bg"].height - 5
					spatialOffset.x = previousSpatialOffset.x;
				}
				
				spatial.scaleX = spatial.scaleY = .3
				var delay:Number = i * .1;
				
				TweenUtils.entityTo( balloonEntity, Spatial, BALLOON_TWEEN_DURATION, {scaleX:1, scaleY:1, ease:Bounce.easeOut}, "", delay );
				SceneUtil.delay( group, delay, Command.create( EntityUtils.visible, balloonEntity, true ) );
				
				group.addEntity(balloonEntity);
				
				ToolTipCreator.addToEntity(balloonEntity);
				EntityUtils.getChildById(balloonEntity, "tooltip", false).remove(FloatingToolTip);
				
				prevSpatial = spatial;
				previousSpatialOffset = spatialOffset;
				prevDisplay = display
			}
		}
		
		
		private function handleQuestionUp(entity:Entity): void 
		{
		}
		
		private function handleQuestionDown(entity:Entity, owner:Entity, balloonEntities:Vector.<Entity>):void
		{
			var display:Display = entity.get(Display) as Display
			display.displayObject["bg"].gotoAndStop(1)	
			//shellApi.soundManager.play( "effects/npc_click_01.mp3" );
			AudioUtils.play(this.group.shellApi.sceneManager.currentScene, SoundManager.EFFECTS_PATH + "npc_click_01.mp3");
			
			// create new word balloon entity for chosen answer, uses same DialogData 
			var wordBalloon:WordBalloon = entity.get(WordBalloon) as WordBalloon;
			var answerComplete:Function = Command.create( handleChosenQuestionBubbleRemoved, wordBalloon.answer, wordBalloon.answerTarget  )
			_balloonCreated.addOnce( Command.create(handleChosenBalloonCreated, answerComplete) );	// listen for next word balloon to be created, on that creation 
			displayStatement(owner, wordBalloon.dialogData);
			
			removeQuestions( balloonEntities )
		}
		
		private function handleQuestionOver(entity:Entity):void
		{
			var display:Display = entity.get(Display) as Display;
			display.displayObject["bg"].gotoAndStop(2);
		}
		
		private function handleQuestionOut(entity:Entity):void
		{
			var display:Display = entity.get(Display) as Display;
			display.displayObject["bg"].gotoAndStop(1);
		}
		
		/**
		 * Called once the actual speech balloon (NOT the question balloon) is created based on the users choice.
		 * Once complete, calls 
		 * @param wordBalloonEntity
		 * 
		 */
		private function handleChosenBalloonCreated(wordBalloonEntity:Entity, onRemoved:Function ): void 
		{
			var wordBalloon:WordBalloon = wordBalloonEntity.get(WordBalloon) as WordBalloon;
			wordBalloon.removed.addOnce( onRemoved );
		}
		
		private function handleChosenQuestionBubbleRemoved( wordBalloon:WordBalloon, answer:DialogData, answerTarget:Entity ): void 
		{
			if( answer != null )
			{
				loadWordBalloon( answerTarget, answer);
				Dialog( answerTarget.get(Dialog)).speaking = true;
				Dialog( answerTarget.get(Dialog)).initiated = false;
			}
		}
		
		private function removeQuestions( balloonEntities:Vector.<Entity> ):void
		{
			if (balloonEntities != null)
			{
				var balloonEntity:Entity;
				var wordBalloon:WordBalloon;
				
				for (var i:int = 0; i < balloonEntities.length ; i++) 
				{
					balloonEntity = balloonEntities[i]
					wordBalloon = balloonEntity.get(WordBalloon);
					if( wordBalloon )
					{
						wordBalloon.removed.removeAll();
						wordBalloon.suppressEventTrigger = true;
						wordBalloon.lifespan = 0;
					}
				}
				
				balloonEntities = null;
			}
		}
		
		private function loadWordBalloon(target:Entity, dialogData:DialogData):void
		{
			
			// TODO :: this path may not work from all groups?
			this.group.shellApi.loadFile(this.group.shellApi.assetPrefix + Dialog( target.get( Dialog )).balloonPath, createWordBalloon, target, dialogData);
			// for some reason, the following call is not only unnecessary,
			// if executed it will cause doubling of the playback.
			// no idea how the audio is being triggered elsewhere.
			//playDialogAudio(target.get(Audio), dialogData);
		}
		
		private function createWordBalloon(asset:DisplayObjectContainer, target:Entity, dialogData:DialogData):void
		{
			var offset:Point = getBalloonOffset( target );
			
			var dialogContainer:DisplayObjectContainer = this.defaultDialogContainer;
			var dialog:Dialog = target.get(Dialog);
			if(dialog && dialog.container)
			{
				dialogContainer = dialog.container;
			}
			try
			{
				var balloonEntity:Entity = _wordBalloonCreator.createEntity(dialogContainer.addChild(asset) as MovieClip, target, dialogData, offset, null, null, this.group.shellApi.profileManager.active.dialogSpeed, false, cameraLimits);
				target.group.addEntity(balloonEntity);
				_balloonCreated.dispatch(balloonEntity);
			}
			catch (e:Error)
			{
				trace("CharacterDialogSystem: can't create word balloon");
			}
		}
		
		private function getBalloonOffset( target:Entity ):Point
		{
			var offset:Point = new Point();
			var dialog:Dialog = target.get( Dialog );
			var edge:Edge = target.get( Edge );
			if ( dialog && edge )
			{
				if ( dialog.dialogPositionPercents )
				{
					offset.x = edge.rectangle.width * dialog.dialogPositionPercents.x;
					offset.y = edge.rectangle.height * -dialog.dialogPositionPercents.y;
				}
			}
			
			return offset;
		}
		
		private function checkMotionLimit( speaker:Entity ):Boolean
		{
			// check speaker's velocity, make sure below threshold before making balloons
			var speakerMotion:Motion = speaker.get( Motion );
			if( speakerMotion != null )
			{
				if(Math.abs(speakerMotion.velocity.x) > SceneDialogSystem.SPEAKER_MAX_VELX)
				{
					return false;
				}
			}
			return true;
		}
		
		//Carried over from CharacterDialogView. Unused.
		/*private function playDialogAudio(audio:Audio, dialogData:DialogData):void
		{
			if(audio)
			{
				if(dialogData.audioUrl)
				{
					audio.play("speech/" + dialogData.audioUrl);
				}
			}
		}*/
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			if(_balloonCreated != null)
			{
				_balloonCreated.removeAll();
			}
			
			super.removeFromEngine(systemManager);
		}
		
		[Inject]
		public var _shellApi:ShellApi;
	}
}