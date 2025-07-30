import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:textfield_tags/textfield_tags.dart';

class TagFormField extends StatelessWidget {
  final StringTagController tagController;
  final String? Function(String)? validator;

  const TagFormField({super.key, required this.tagController, this.validator});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFieldTags<String>(
      textfieldTagsController: tagController,
      textSeparators: const [' ', ','],
      letterCase: LetterCase.normal,
      validator: validator,
      inputFieldBuilder: (context, inputFieldValues) {
        return TextField(
          onTap: () {
            tagController.getFocusNode?.requestFocus();
          },
          controller: inputFieldValues.textEditingController,
          focusNode: inputFieldValues.focusNode,
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 3.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 3.0,
              ),
            ),
            helperStyle: TextStyle(color: theme.colorScheme.primary),
            hintText: inputFieldValues.tags.isNotEmpty ? '' : "Enter tag...",
            errorText: inputFieldValues.error,
            prefixIconConstraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            prefixIcon: inputFieldValues.tags.isNotEmpty
                ? SingleChildScrollView(
                    controller: inputFieldValues.tagScrollController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Gap(10),
                        ...inputFieldValues.tags.map((String tag) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(20.0),
                              ),
                              color: theme.colorScheme.primary,
                            ),
                            margin: const EdgeInsets.only(right: 10.0),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 4.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4.0),
                                InkWell(
                                  child: Icon(
                                    Icons.cancel,
                                    size: 14.0,
                                    color: theme.colorScheme.onPrimary
                                        .withAlpha(200),
                                  ),
                                  onTap: () {
                                    inputFieldValues.onTagRemoved(tag);
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  )
                : null,
          ),
          onChanged: inputFieldValues.onTagChanged,
          onSubmitted: inputFieldValues.onTagSubmitted,
        );
      },
    );
  }
}
