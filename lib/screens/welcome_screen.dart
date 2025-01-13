import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:legal_bot/screens/signin_screen.dart';
import 'package:legal_bot/screens/signup_screen.dart';
import 'package:legal_bot/widgets/custom_scaffold.dart';
import 'package:legal_bot/widgets/welcome_button.dart';

import '../theme/theme.dart';

class WelcomeScreen extends StatelessWidget{
  const WelcomeScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: Column(
        children: [
          Flexible(
            flex: 0,
              child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 40.0,
            ),
            child: Center(
                child: RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: '\n',
                          style: TextStyle(
                            fontSize: 15.0,
                            //fontWeight: FontWeight.w400,
                          )),
                        TextSpan(
                            text:
                                '\n',
                            style: TextStyle(
                              fontSize: 20,
                              // height: 0,
                            ))
                        ],
                      ),
                    ),
                  ),
                )),
          Flexible(
            flex: 1,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Row(
                children: [
                  const Expanded(
                    child: WelcomeButton(
                      buttonText: 'Sign in',
                      onTap: SignInScreen(),
                      color: Colors.transparent,
                      textColor: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: WelcomeButton(
                      buttonText: 'Sign up',
                      onTap: const SignUpScreen(),
                      color: Colors.white,
                      textColor: lightColorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}