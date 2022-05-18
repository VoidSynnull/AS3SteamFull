package game.creators.ui
{
	import com.poptropica.AppConfig;
	
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.SpatialOffset;
	import engine.creators.InteractionCreator;
	import engine.data.AudioWrapper;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.motion.FollowTarget;
	import game.components.ui.ToolTipActive;
	import game.components.ui.WordBalloon;
	import game.data.PlatformType;
	import game.data.scene.characterDialog.DialogData;
	import game.data.ui.ToolTipType;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.TextUtils;
	
	import org.osflash.signals.Signal;

	public class WordBalloonCreator
	{
		/**
		 *
		 * @param	displayObject
		 * @param	target
		 * @param	dialogData
		 * @param	offset - offset from target's Spatial x &amp; y
		 * @param	answerTarget
		 * @param	answer
		 * @param	dialogSpeed
		 * @param	isQuestion - is WordBalloon a question (questions do not necessarily have answers - Zen koan )
		 * @return
		 */

		public function createEntity(displayObject:MovieClip, target:Entity, dialogData:DialogData, offset:Point = null, answerTarget:Entity = null, answer:DialogData = null, dialogSpeed:Number = NaN, isQuestion:Boolean = false, cameraLimits:Rectangle = null):Entity
		{
			if (isNaN(dialogSpeed)) 
			{
				dialogSpeed = Dialog.DEFAULT_DIALOG_SPEED;
			}

			var entity:Entity = new Entity();
			var display:Display = new Display(displayObject);
			entity.add(display);

			// add Spatial
			var dialog:Dialog = target.get(Dialog);
			var targetSpatial:Spatial;

			targetSpatial = target.get(Spatial);
			
			// add SpatialOffset
			var spatialOffset:SpatialOffset = new SpatialOffset();
			entity.add(spatialOffset);
			
			display = target.get(Display);
			
			if(display)
			{
				var point:Point = DisplayUtils.localToLocal(display.container,displayObject.parent);
				spatialOffset.x = point.x;
				spatialOffset.y = point.y;
			}
			
			var spatial:Spatial = new Spatial( targetSpatial.x, targetSpatial.y );
			spatial.scaleX = spatial.scaleY = 0;	// starts at 0, we scale this up to show it.
			entity.add(spatial);			
			
			if (offset != null)
			{
				spatialOffset.x += offset.x;
				spatialOffset.y += offset.y;
			}
			
			// add Sleep, prevent sleeping when offscreen
			entity.add(new Sleep(false, true));

			EntityUtils.addParentChild(entity, target);

			// add WordBalloon
			var wb:WordBalloon = new WordBalloon();
			wb.cameraLimits = cameraLimits;
			wb.removed = new Signal();
			wb.dialogData = dialogData;

			if (isQuestion)
			{
				InteractionCreator.addToEntity(entity, [InteractionCreator.DOWN, InteractionCreator.OVER, InteractionCreator.OUT,InteractionCreator.UP]);
				if(answer)
				{
					wb.answer = answer;
					wb.answerTarget = answerTarget;
					wb.speak = false;  // this is an answer balloon, so the character should not speak when it appears
					
					// add a cursor rollover on desktop
					if(AppConfig.platformType == PlatformType.DESKTOP)
					{
						ToolTipCreator.addUIRollover(entity, ToolTipType.CLICK);
						var toolTipActive:ToolTipActive = entity.get(ToolTipActive);
						toolTipActive.useParentDisplayForHitTest = false;  // in this case we want the cursor to hittest against this entity's display, not the parents.
					}
				}
			}
			else
			{
				if(dialogData.dialog)
				{
					if(dialogData.audioUrl)
					{
						var audio:Audio = target.get(Audio);
						if(!audio.isPlaying(SoundManager.SPEECH_PATH + dialogData.audioUrl))
						{
							var wrapper:AudioWrapper = audio.play(SoundManager.SPEECH_PATH + dialogData.audioUrl);
							wrapper.complete.addOnce(Command.create(audioDone, wb));
							wb.lifespan = 100000000;
						}
					}
					else
					{
						wb.lifespan = WordBalloonCreator.DIALOG_MIN_TIME + (dialogSpeed * WordBalloonCreator.DIALOG_TIME_MULTIPLIER) * dialogData.dialog.length;
					}
					wb.speak = true;  // this is an question or statement balloon, so the character should speak when it appears
				}
			}
			entity.add(wb);

			// add FollowTarget
			var followTarget:FollowTarget = new FollowTarget();
			followTarget.target = targetSpatial;
			followTarget.rate = .2;
			entity.add(followTarget);
			
			// add TextField to displayObject
			var tf:TextField = displayObject["tf"] as TextField;
			tf = TextUtils.refreshText(tf);
			
			tf.mouseEnabled = false;
			tf.autoSize = TextFieldAutoSize.CENTER;
			
			if(dialogData.dialog)
				tf.htmlText = TextUtils.formatAsBlock(dialogData.dialog);
			tf.width = tf.textWidth + 10;
			if(dialogData.textStyleData != null)
			{
				TextUtils.applyStyle(dialogData.textStyleData, tf);
			}
			
			var margin:Number = BASE_TEXT_MARGIN + tf.width / 50; // slightly more margin for large word balloons
				
			// if platform is Mobile (as opposed to Desktop or Tablet) increase size of text
			//if(AppConfig.platformType == PlatformType.MOBILE)
			//{
				//tf.scaleX = tf.scaleY = 2;
			//}
			
			displayObject.bg.height = tf.textHeight * tf.scaleX + margin*1.75;
			displayObject.bg.width = tf.textWidth * tf.scaleY + margin*2;

			var bgBounds:Rectangle = displayObject.bg.getBounds(displayObject);
			tf.x = -tf.width/2;
			tf.y = bgBounds.top + margin * .78;

			if(!answer)
			{
				var scale:Number =  1;
				if( Spatial(target.get(Spatial)).scaleX < 0 )
				{
					scale = -1;
				}
				displayObject.line.scaleX = scale;
			}
			
			// 
			if(dialogData.triggerEvent && dialogData.triggerEvent.triggerFirst)
			{
				//dialogData.triggerEvent);
			}

			return(entity);
		}

		private function audioDone(wb:WordBalloon):void
		{
			wb.lifespan = 0;
		}

		public static function getDialogTime(dialog:String, dialogSpeed:Number = NaN):Number
		{
			if (isNaN(dialogSpeed)) { dialogSpeed = Dialog.DEFAULT_DIALOG_SPEED; }

			return(WordBalloonCreator.DIALOG_MIN_TIME + (dialogSpeed * WordBalloonCreator.DIALOG_TIME_MULTIPLIER) * dialog.length);
		}

		private const BASE_TEXT_MARGIN:int = 14;

		private static const DIALOG_MIN_TIME:Number = 1;
		private static const DIALOG_TIME_MULTIPLIER:Number = 0.05;
	}
}
