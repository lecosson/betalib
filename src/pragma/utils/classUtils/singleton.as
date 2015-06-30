package pragma.utils.classUtils
{
	/**
	 * Создание синглтона (единственного экземпляра класса). Возвращаемая функция создает синглтон класса <code>$class</code> или возвращает синглтон этого класса, если он был создан ранее
	 * при попытке создать синглтон повторно будет выдано предупреждение
	 * <br/><br/>
	 * Примеры вызова:
	 * <code>
	 * <br/><br/><b>// без аргументов</b>
	 * <br/>var a:AnyClass = new singletone(AnyClass);
	 * <br/><br/><b>// с аргументами</b>
	 * <br/>var b:AnyClass = new singletone(AnyClass, arg0, arg1, ... argN);
	 * <br/><br/><b>// из существующего экземпляра - возвращается имеющийся либо данный назначается синглтоном.</b> 
	 * <br/>var c:AnyClass = new AnyClass(arg0, arg1, ... argN);
	 * <br/>... 
	 * <br/>var d:AnyClass = new singletone(c);
	 * <br/><br/><b>// инициализация в конструкторе</b>
	 * <br/>public function SomeClass(arg0, arg1, ... argN) {
	 * <br/>... 
	 * <br/>singletone(this);
	 * <br/>... 
	 * <br/>}
	 * <br/><br/><b>// инициализация в конструкторе с проверкой на существование синглтона данного класса.</b>
	 * <br/>public function SomeClass(arg0, arg1, ... argN) {
	 * <br/>... 
	 * <br/>if (this===singletone(this)) {...};
	 * <br/>... 
	 * <br/>}
	 * <br/><br/><b>// освобождение синглтона. Если синглтон является $Idestroyable, он будет уничтожен.</b>
	 * <br/>... 
	 * <br/>singleton.destroy(SomeClass);
	 * <br/>... 
	 * </code>
	 * <br/><br/>
	 * @author Lecosson
	 * @version 2012-10-06
	 * @param $class: класс, экземпляр которого нужно создать
	 * @param $args: список аргументов для конструктора класса
	 * @return создает синглтон класса <code>$class</code> или возвращает синглтон этого класса, если он был создан ранее
	 */
//	public function get singleton():* {return SingletonStorage.getSingleton;}
	public const singleton:Function = SingletonStorage.getSingleton;
	singleton['destroy']=SingletonStorage.destroySingleton;
	singleton['check']=SingletonStorage.checkSingleton;
}

import avmplus.getQualifiedClassName;

import pragma.interfaces.$IDestroyable;
import pragma.utils.classUtils.createInstance;

/**
 * Класс-сателлит для реализации синглтона. Используется как хранилище статических переменных, списка синглтонов, функций для работы с ними
 */
internal class SingletonStorage {
	
	public static const storage:Object=new Object();
	
	/**
	 * проверяет класс или его экземпляр на наличие экземпляра данного класса в списке синглтонов
	 * @param $class - проверяемый класс или инстанс класса
	 * @return true, если синглтон данного класса зарегистрирован, иначе false
	 */
	public static function checkSingleton($class:*=null):Boolean {
		var className:String=getQualifiedClassName($class);
		return storage.hasOwnProperty(className); //если такой синглтон уже был создан, вернем true
	}

	/**
	 * удалает класс из списка зарегистрированных синглтонов. Если удаляемый объект является $IDestroyable, то он уничтожается.
	 * @param $class - удаляемый класс или инстанс класса
	 */
	public static function destroySingleton($class:*=null):void {
		var className:String=getQualifiedClassName($class);
		if (storage.hasOwnProperty(className)) { //если такой синглтон уже был создан
			var instance:*=storage[className];
			delete storage[className];
			if (instance is $IDestroyable) (instance as $IDestroyable).destroy();
		}
	}
		
	/**
	 * создает экземпляр синглтона или возвращает готовый, если он уже имеется.
	 * @param $class класс создаваемого/получаемого синглотона или экземпляр этого класса
	 * @param $args параметры, передаваемые в конструктор класса, если новый экземпляр будет создаваться
	 * @return экземпляр класса
	 */
	public static const getSingleton:Function=function getSingleton($class:*=null, ...$args):* {
		var result:Function; //функция, которая фернет синглтон в конце работы
		var singleton:*; //экземпляр, который будем возвращать
		var className:String=getQualifiedClassName($class); //класс, экземпляр которого надо вернуть
		
		if ($class==null) {
			// это пустой вызов
			//TODO: логировать исключение, возможно также следует вернуть Proxy и логировать все обращения
			result=function ():* {return null};
		} else {
			//если есть с чем работать 
			if ($class is Class) { // это класс
				if (storage.hasOwnProperty(className)) {
					//берем результат из хранилища
					result=function ():* {
						singleton=storage[className];
						return singleton;
					}
				} else {
					// генерируем и возвращаем экземпляр класса
					result=function ():* {
						var args:Array=$args.slice();
						if ($class.hasOwnProperty('getInstanse')) {
							// если класс поддерживает такую инстанциацию, используем это
							singleton=$class.getInstanse.apply(this,args);
						} else {
							args.unshift($class);
							singleton=createInstance.apply(this,args);
						}
						storage[className]=singleton;
						return singleton;
					}
				}
			} else {
				// это экземпляр класса
				if (storage.hasOwnProperty(className)) {
					result=function ():* {
						singleton=storage[className];
						return singleton;
					}
				} else {
					// записываем в хранилище и возвращаем данный экземпляр класса
					result=function ():* {
						singleton=$class;
						storage[className]=singleton;
						return singleton;
					}
				}
			}
		}
		return (result());
	}
}