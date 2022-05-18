package game.ui.screenCapture
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	import game.util.TextUtils;

	public class CaptionData extends Sprite
	{
		public var alignX:Number;
		public var alignY:Number;
		public var tf:TextField;
		public function CaptionData(caption:String, font:String= "", alignX:Number = .5,alignY:Number = 1)
		{
			this.alignX = alignX;
			this.alignY = alignY;
			var tf:TextField = new TextField();
			tf.autoSize = TextFieldAutoSize.CENTER;
			tf.text = caption;
			tf.x = -tf.width * alignX;
			tf.y = -tf.height * alignY + tf.height * .3;
			tf = TextUtils.refreshText(tf, font);
			addChild(tf);
		}
	}
}